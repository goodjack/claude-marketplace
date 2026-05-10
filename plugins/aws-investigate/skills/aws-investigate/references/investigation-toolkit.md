# 調查工具箱

定期掃描和特定問題調查共用的深入分析步驟。依問題性質選擇需要的工具，不必每次全用。

**入口 B（特定問題）直接從這裡開始。** 入口 A（定期掃描）在 Scan 5 篩選後，對每個 P1/P2 問題進入這裡。

---

## T1: Root Cause 追查（效能劣化 / 錯誤爆發時）

> **核心原則**：效能劣化或錯誤爆發時，第一個問題不是「程式碼哪裡有問題」，而是「什麼時候開始的」。時間起點追查 → 交叉比對部署/變更 → 追蹤共用元件，比直接看程式碼找 code smell 更容易命中真正的 root cause。
>
> **反面教訓**：只做靜態程式碼分析容易「看到合理解釋就停止挖」。例如看到 `for + await` 序列執行就判定為瓶頸，但真正原因可能是底層 dependency 升版改變了 Redis 操作行為（KEYS → SCAN），序列執行只是次要因素。

若問題是單次 error（而非劣化趨勢），跳至 T2。

**T1-1. 追查時間起點**

找出問題「第一次出現」或「開始惡化」的精確時間，不要只統計一個區間的彙總數字：

```
fields @timestamp, responseTime
| filter {問題條件}
| stats count() as cnt, avg(responseTime) as avg_ms by bin(1h)
| sort @timestamp asc
```

目標是找到 `avg_ms` 或 `cnt` 出現跳躍的那個小時。找到後再縮小到 `bin(5m)` 精確追查。

**T1-2. 交叉比對部署與變更**

拿到時間起點後，查該時段前後的部署紀錄。可用工具（詳見 `references/aws-tools.md`）：
- `git log --oneline --after/--before origin/main`（commit 歷史）
- CodePipeline（部署流水線狀態與時間）
- `aws ecs describe-services`（ECS deployment 事件）

若時間起點與部署吻合 → 檢查該部署的 commit diff 與 dependency 變更。

**T1-3. 檢查 dependency 版本差異**

部署包含 dependency 升版時，比對 lockfile diff 找行為變更：

```bash
git diff {deploy_commit}^..{deploy_commit} -- pnpm-lock.yaml package-lock.json poetry.lock
```

重點看核心 dependency 的大版本跳升（如 `unstorage` v1.12→v1.17、`ioredis` 等），然後查對應 changelog 或 PR 是否有行為變更（例如 `KEYS` → `SCAN`、連線池策略改變）。

**T1-4. 跨 endpoint 關聯分析**

如果多個不相關的 endpoint 在同一時間變慢或出錯 → 優先懷疑共用元件（storage driver、DB driver、middleware、Redis），而不是各自的業務邏輯：

```
fields url, responseTime
| filter responseTime > 1000
| stats count() as cnt, avg(responseTime) as avg_ms by url
| sort avg_ms desc
| limit 20
```

若多個 endpoint 的 `avg_ms` 同步突增，找它們共用的底層呼叫（如 `storage.getKeys`、`session.getSessionById`）。

**T1-5. 基礎設施訊號比對**

查 CloudWatch Metrics 確認基礎設施在問題時段是否異常（詳見 `references/aws-tools.md`）。判讀順序：先看 Redis/DB（最常見的共用瓶頸）→ ECS（application 層資源）→ ALB（網路層）。

若指標異常，用 `get-metric-widget-image` 產圖附在報告中（模板見 `references/metrics-charts.md`）。若 T1-2 已找到部署時間點，在圖表加上部署標註（vertical annotation）讓讀者一眼看到轉折。

完成後進入 T2 做細部追蹤。若在此步驟已找到 root cause（如 dependency 升版），可跳過 T2-T3 直接進 T4 追查程式碼。

---

## T2: Trace ID 時序追蹤

trace ID 格式：`Root=1-{hex8}-{hex24}`（AWS X-Ray 格式），搜尋用中間 8 位 hex（如 `69dfb888`）。

### 單一 log group（用 FilterLogEvents，免費）

已知 trace ID + 單一 log group 時，優先使用 FilterLogEvents（無 scan 費用）：

**後端：**

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} \
  --end-time {end_epoch_ms} \
  --filter-pattern '"{trace_id_fragment}"' \
  --profile {profile} --output json
```

**前端：**

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} \
  --end-time {end_epoch_ms} \
  --filter-pattern '"{trace_id_fragment}"' \
  --limit 20 \
  --profile {profile} --output json
```

> **注意**：FilterLogEvents 的 `--start-time` / `--end-time` 是**毫秒**（不是秒）。用 Python 計算：`int(timestamp * 1000)`

### 跨前後端 log group（用 Insights，FilterLogEvents 不支援跨 group）

```bash
aws logs start-query \
  --log-group-names "{backend_log_group}" "{frontend_log_group}" \
  --start-time {start_epoch} --end-time {end_epoch} \
  --query-string 'fields @timestamp, @log, event, @message
    | filter @message like "{trace_id_fragment}"
    | sort @timestamp asc
    | limit 50' \
  --profile {profile} --output json
```

`@log` 欄位可區分來源是哪個 log group。

從時序結果確認：前端何時呼叫後端 → 後端何時呼叫下游服務 → 哪些呼叫快速失敗（毫秒內）vs 卡住（數秒後才回傳）→ 連鎖失敗的起點是哪一層。

---

## T3: 取完整 exception 內容

### 後端

後端 error log 通常有兩種層次：
- **應用層 error handler** 記錄的 log — 帶有 API 路徑和請求資訊，但 exception 詳情不一定完整
- **框架層未捕獲 exception** 記錄的 log — 通常含完整 traceback

> **注意**：不同 logger 對 exception 的記錄方式不同。structlog 將 exception 存在 `exc_info` array 欄位（`[class, message, traceback_object]`）；標準 Python logging 則嵌在 message 中。查詢時先確認你的 logger 實作。
>
> **常見陷阱**：應用層 error handler 的 log 不一定包含完整 exception。若欄位為空，改查同一時段的框架層 exception log（如 ASGI 框架的 `Exception in ASGI application`），或用 trace ID 交叉比對。

**用 FilterLogEvents 取完整 exception（免費，優先使用）：**

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} \
  --end-time {end_epoch_ms} \
  --filter-pattern '"{uuid_or_keyword}" "error"' \
  --limit 5 \
  --profile {profile} --output json
```

**若需要 Insights 的欄位萃取能力（如精確取 exception 詳情）：**

先查應用層 error handler 的 log：

```
fields @timestamp, event, exc_info, logger, lineno
| filter level = "error"
| filter @message like "{uuid_or_keyword}"
| limit 5
```

若 exception 詳情不完整，補查框架層 exception（以 ASGI 為例）：

```
fields @timestamp, event, exc_info, logger
| filter level = "error"
| filter event like "Exception in ASGI"
| filter @message like "{uuid_or_keyword}"
| limit 5
```

> 其他框架替換 filter 條件為對應的未捕獲 exception 關鍵字。

### Traceback 精簡策略

若 traceback 超過 10 行，只保留：
- 最後 5 行 call stack（最接近錯誤發生點的）
- exception class 名稱
- exception message 全文
- 第一行 call stack（最外層入口點）

不要回傳完整 traceback。主對話可以用 T4 程式碼追查看原始碼。

### 前端（取 `err` 欄位）

**用 FilterLogEvents（免費，優先使用）：**

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} \
  --end-time {end_epoch_ms} \
  --filter-pattern '"{uuid_or_keyword}" "error"' \
  --limit 3 \
  --profile {profile} --output json
```

解析完整 JSON：

```bash
python3 -c "
import json
raw = '''<貼上 @message 的值>'''
d = json.loads(raw)
print(json.dumps(d, indent=2, ensure_ascii=False))
"
```

---

## T4: 程式碼追查

**後端**（根據 log 欄位追查）：
- `logger` / module 欄位 → Python 模組路徑（如 `app.services.user` → `app/services/user.py`）
- `lineno` 欄位 → 行號
- API path → 路由模組（依專案路由慣例推導）
- function name → Grep 搜尋定義和呼叫鏈

**前端**（根據 `namespace` 或 module 追查）：
- Nuxt SSR：`namespace` → 對應服務檔案（如 `myapp:server:services:SomeApi` → `server/services/SomeApi.ts`）
- 其他 SSR 框架：依其 logger 的 module identifier 慣例推導
- `path` → 對應 API route 或 server handler

追查步驟：
1. Grep 搜尋 logger / namespace 或函數名稱
2. Read 讀取對應檔案，確認錯誤路徑
3. 追蹤呼叫鏈（前端 route → service → 後端 API → 下游服務）
4. 確認 503 / NoneType 等防禦性缺陷的位置

---

## T5: Redis Memory 暴增調查

> **適用情境**：Redis DatabaseMemoryUsagePercentage 或 CurrItems 異常成長。
> **核心原則**：先判斷是「key 數爆炸」還是「單 key value 過大」，再追查 key 來源。

**T5-1. 確認成長類型**

```bash
# CurrItems（key 總數）— 線性成長 = 大量新 key
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache --metric-name CurrItems \
  --dimensions Name=CacheClusterId,Value={node} \
  --start-time {start} --end-time {end} --period 300 --statistics Average \
  --profile {profile} --output json

# BytesUsedForCache — 對比 CurrItems 判斷平均 key size
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache --metric-name BytesUsedForCache \
  --dimensions Name=CacheClusterId,Value={node} \
  --start-time {start} --end-time {end} --period 300 --statistics Average \
  --profile {profile} --output json
```

- CurrItems 線性成長 + BytesPerKey 穩定 ≈ 100-500 bytes → **session 汙染**（大量小 key）
- CurrItems 穩定 + BytesUsedForCache 暴增 → **大 value key**（如 cache 了巨大 JSON）

確認異常後，產圖附在報告中（使用 `references/metrics-charts.md`「Redis：Key 數量 + Memory」模板）。

**T5-2. 確認命令類型**

```bash
# SetTypeCmds vs baseline — SET 命令是否暴增
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache --metric-name SetTypeCmds \
  --dimensions Name=CacheClusterId,Value={node} \
  --start-time {start} --end-time {end} --period 300 --statistics Sum \
  --profile {profile} --output json
```

- SetTypeCmds 只微增但 CurrItems 爆炸 → 每個 SET 都是新 key（session、per-UUID cache）
- SetTypeCmds 暴增 → 可能是程式碼 bug 或批次任務大量寫入

可搭配產圖（使用 `references/metrics-charts.md`「Redis：命令類型」模板）對比 SET vs GET 趨勢。

**T5-3. 追查 key 前綴來源（需 Redis CLI 或 SCAN）**

如果可以進入 Redis（或問 SRE），用 `{config.redis_key_prefixes}` 中的前綴：

```bash
redis-cli --scan --pattern "{prefix}:*" | wc -l
```

對每個設定的前綴執行，確認哪一類成長最快。

**T5-4. 比對流量來源**

Key 成長速率 vs ALB 請求速率的比值揭示 per-request 寫入機制：
- 比值 ≈ 1 → 每個請求建 1 key（session）
- 比值 ≈ 2 → 每個請求建 2 keys（AC cache: uuid + pid）
- 比值 >> 1 → 每個請求觸發多筆 cache 寫入（需追查 code path）

**T5-5. 常見 root cause**

| 症狀 | Root cause | 確認方式 |
| --- | --- | --- |
| Bot 流量高 + CurrItems 線性成長 + session prefix 佔大宗 | `saveUninitialized: true` + bot 不帶 cookie | 查 ALB UA 確認 bot 比例 + 查前端 session config |
| 特定時間點 key 突增 + 高基數路徑 | 排程任務打大量 unique 資源 | 查 task/worker log group 和 backend ALB 流量 |
| CurrItems 成長 + Evictions > 0 | Redis 已觸發 LRU 淘汰但來不及 | 確認 maxmemory-policy 設定 |
