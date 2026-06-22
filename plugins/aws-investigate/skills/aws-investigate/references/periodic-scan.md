# 定期掃描流程

適用時機：統整一段時間（如一週）的 error 全貌，找出需要修復的系統性問題。

**完整流程：Scan 1-4 彙總 → Scan 5 篩選 → 對 🔴 高/🟡 中 問題執行調查工具箱 → 產出報告。**

---

## Scan 1: 後端 error 分層彙總

先 group by level 確認後端 level 分布（見 `references/query-basics.md` Log Level 判讀策略），再依優先序查詢。

以下查詢沿用內建的 Python structlog / ASGI / Nuxt SSR 經驗。若結果不符合實際 log，先用探索查詢釐清欄位。

### Step 0：探索 error 分布

首次使用或不確定 log 格式時，先看整體 error 的 event/message 分布：

```
fields event
| filter level = "error"
| stats count() as cnt by event
| sort cnt desc
| limit 30
```

從結果中辨識兩類 error：
- **外部 API 呼叫失敗**（通常含 status code、URL、timeout 等關鍵字）
- **內部 exception**（通常含 Exception、Error、Traceback 等關鍵字）

辨識後，用以下兩層架構分別查詢。若 `config.local.yaml` 有定義 `backend_error_keywords`，直接使用對應關鍵字作為 filter 條件。

### 第一層：外部服務 / API 呼叫失敗

> **重要**：必須先 `filter` 再 `parse`。CloudWatch 的 `parse` 不會過濾紀錄——不匹配的紀錄仍保留在結果中，萃取欄位為空值，會在 `stats` 彙總時被歸為同一組（空值組），產生誤導性的大數字。

依你的 API caller log 格式建構查詢。以下是常見範例：

**範例 A：自訂 API caller（如 `occur ERROR` 格式）**

適用於 API caller 以固定格式記錄外部呼叫失敗的專案：

```
fields @timestamp, event
| filter level = "error"
| filter event like "occur ERROR"
| parse event "* occur ERROR: Error message: *" as func_name, error_detail
| parse error_detail "status is *, reason is *," as status_code, reason
| filter func_name != ""
| stats count() as cnt by func_name, status_code, reason
| sort cnt desc
```

**範例 B：通用 — 直接用 event 分群**

適用於不確定 log 格式、或 API caller 沒有統一格式的專案：

```
fields @timestamp, event
| filter level = "error"
| filter event not like "Exception"
| parse event /(?<error_type>[A-Za-z]+Error|[A-Za-z]+Exception)/
| parse event /"(?:path|url)":"(?<path>[^"]+)"/
| stats count() as cnt by error_type, path
| sort cnt desc
| limit 30
```

### 第二層：程式碼拋出的未處理 exception

**ASGI 框架（FastAPI / Starlette / uvicorn）：**

```
fields @timestamp, event
| filter level = "error"
| filter event like "{config.backend_error_keywords.unhandled_exception}"
| parse event /(?<error_type>\w+Error)/
| stats count() as cnt by error_type
| sort cnt desc
| limit 30
```

> 預設關鍵字 `Exception in ASGI application` 是 uvicorn 在未捕獲 exception 時印出的通用訊息。其他框架請在 `config.local.yaml` 的 `backend_error_keywords.unhandled_exception` 填入對應關鍵字，或用 Step 0 的探索查詢找出。

> **注意**：若 logger 使用 Python repr 格式記錄 dict，key 和 value 會用**單引號**（`'path': '/api/...'`），parse 時注意引號格式。

**第三層（可選）：Top errors 每日分布**

對 Scan 1 第一、二層的 **top 3** error 加跑時間分布，提早區分「慢性問題」vs「事件爆發」：

```
fields @timestamp
| filter level = "error"
| filter event like "{top_error_keyword}"
| stats count() as cnt by bin(1d)
| sort @timestamp asc
```

穩定的每日數字 → 慢性問題（架構缺陷、資料不一致）。某天突然暴增 → 事件爆發（部署、攻擊、上游異常），需進入 T1 追時間起點。

**加查 warn（視情況）：**

```
fields @timestamp, event, logger
| filter level = "warn"
| stats count() as cnt by logger, event
| sort cnt desc
| limit 30
```

---

## Scan 2: 前端 error 彙總

> 以下查詢基於 Nuxt SSR（pino logger）的 JSON 格式。其他 SSR 框架的 log 結構可能不同，請先用 Scan 1 Step 0 的探索方式了解你的前端 error 分布，再依實際格式調整查詢。

前端錯誤分兩類，分別查：

**A. HTTP 呼叫失敗（有 statusCode）**

`err.data.statusCode` 是巢狀 JSON，無法直接欄位 filter，改用 `@message like` + `parse`：

```
fields @timestamp, namespace, @message
| filter level = "error"
| filter @message like /"statusCode":5/
| parse @message /"statusCode":(?<status_code>\d+)/
| parse @message /"namespace":"(?<svc>[^"]+)"/
| stats count() as cnt by status_code, svc
| sort cnt desc
| limit 30
```

**B. 純前端 / Node.js 錯誤（無 statusCode）**

包含：Nuxt middleware 錯誤、Node.js runtime 例外、OIDC 流程錯誤、FetchError、全域錯誤捕捉器記錄的 API 錯誤等：

```
fields @timestamp, namespace, @message
| filter level = "error"
| filter @message not like /"statusCode":/
| parse @message /"msg":"(?<err_msg>[^"]+)"/
| stats count() as cnt by namespace, err_msg
| sort cnt desc
| limit 30
```

**非 5xx 的前端 error（SDK 異常、timeout 等）：**

```
fields @timestamp, namespace, @message
| filter level = "error"
| filter @message not like /"statusCode":4/
| parse @message /"msg":"(?<err_msg>[^"]+)"/
| stats count() as cnt by namespace, err_msg
| sort cnt desc
| limit 30
```

**加查 warn（視情況）：**

```
fields @timestamp, namespace, @message
| filter level = "warn"
| parse @message /"msg":"(?<warn_msg>[^"]+)"/
| stats count() as cnt by namespace, warn_msg
| sort cnt desc
| limit 30
```

> **注意**：若前端有全域錯誤捕捉器，該模組捕捉的錯誤通常是後端 4xx/5xx 的反射。計算時注意與後端 error log 去重，避免重複計算。

---

## Scan 3: 雜訊過濾 — 爬蟲 / 安全掃描 / 攻擊流量識別

對大量同類錯誤，先比對以下常見特徵快速分類，再決定是否需要深入：

**A. 安全掃描器 / 攻擊流量特徵**

| 特徵 | 識別方式 | 判斷 |
| --- | --- | --- |
| Path traversal | URL 含 `%c0%af..`、`../etc/passwd`、`../windows/win.ini` | 攻擊雜訊 |
| 整數溢位 | query parameter 含 `18446744073709551617`（uint64+1）、`4294967297`（uint32+1）、極大負數 | 攻擊雜訊，但後端應回 422 而非 500 |
| Header injection | body/UUID 欄位含 `\r\nAppScanHeader:`、`\r\nSecondAppScanHeader:` | AppScan 掃描器 |
| Fuzzer probing | 搜尋欄位填入隨機短字串（非正常使用者輸入模式） | 攻擊雜訊 |

安全掃描流量可能來自委託的資安掃描或外部攻擊。**兩者都需要監控**——資安掃描暴露的 input validation 缺口（如極端整數值導致 500 而非 422）是真實的防禦弱點，應記錄在報告中。

> 辨識方式：同一 IP / User-Agent 在短時間內密集打多個 endpoint、使用 HeadlessChrome、請求 pattern 有系統性規律。

**B. 爬蟲行為識別**

對大量同類錯誤，驗證是否為爬蟲模式：

```
fields @timestamp, event
| filter level = "error"
| filter event like "{條件}"
| parse event /'path': '(?<full_path>[^']+)'/
| parse full_path /\/api\/\w+\/(?<id>[^\/]+)/
| stats count() as total_hits, count_distinct(full_path) as unique_paths by id
| sort total_hits desc
| limit 20
```

每個 ID 命中固定數量的不同路徑 → 通常是爬蟲。

---

## Scan 4: ALB 查詢（Athena）

CloudWatch 只有應用層 log；**ALB 層的異常**（container crash、gateway timeout、非預期狀態碼）需查 Athena。

從 `{config.athena}` 讀取（需要 `workgroup` 和 `tables`）。若未設定，用 AskUserQuestion 蒐集：
1. Athena workgroup 名稱
2. 列出可用 ALB table，讓使用者選擇（checkbox）：

```sql
SHOW TABLES IN aws
```

**Table schema（可用欄位）：**

| 欄位                     | 說明                                                  |
| ------------------------ | ----------------------------------------------------- |
| `time`                   | 請求時間（ISO 8601 字串，UTC）                        |
| `elb_status_code`        | ALB 回給 client 的狀態碼                              |
| `target_status_code`     | backend 回給 ALB 的狀態碼；`-` = container 完全沒回應 |
| `target_processing_time` | backend 處理時間（秒）；`-1` = ALB timeout 超過 60s   |
| `request_verb`           | HTTP method                                           |
| `request_url`            | 完整 URL                                              |
| `client_ip`              | 請求來源 IP                                           |

**查詢設計原則：**

ALB log 反映的是網路層事實，不是只有 5xx 才值得注意：

- `5xx`：伺服器 / 基礎設施錯誤，一定要看
- `422`：非預期的 validation failure，可能是前端傳錯資料，或有人在 try payload
- `405`：前後端 HTTP method 不對齊
- `404` 集中在特定 endpoint 且量大：可能是有人在 probe API，或資料遺失
- `target_status_code = '-'`：container 完全無回應，疑似 OOM crash 或重啟 → 用 ECS 容器診斷確認（見 `references/aws-tools.md`）
- `target_processing_time > 10s`：慢查詢，可能造成連鎖問題或 timeout
- 特定 `client_ip` 反覆出現：可能是爬蟲或攻擊

起始查詢（拿到分布後再決定深入哪條線）：

```sql
SELECT elb_status_code, target_status_code,
       request_verb,
       regexp_extract(request_url, 'https?://[^/]+(/.+?)(\?|$)', 1) AS path_pattern,
       COUNT(*) AS cnt
FROM {athena_table}
WHERE from_iso8601_timestamp(time)
        BETWEEN from_iso8601_timestamp('{start_utc}')
            AND from_iso8601_timestamp('{end_utc}')
  AND elb_status_code NOT IN (200, 201, 204, 301, 302, 304)
GROUP BY 1, 2, 3, 4
ORDER BY cnt DESC
LIMIT 100
```

**執行方式（三步驟）：**

```bash
# 1. 送出查詢
aws athena start-query-execution \
  --query-string "{SQL}" \
  --work-group "{workgroup}" \
  --profile {profile} --output json
# → 取得 QueryExecutionId

# 2. 等完成（約 10 秒，視資料量）
sleep 10 && aws athena get-query-execution \
  --query-execution-id "{id}" \
  --profile {profile} --output json

# 3. 取結果
aws athena get-query-results \
  --query-execution-id "{id}" \
  --profile {profile} --output json
```

> **時間格式**：`from_iso8601_timestamp()` 接受 ISO 8601 字串。使用者時區為 `{config.timezone.label}`（UTC+{config.timezone.offset_hours}），需換算為 UTC。例如 UTC+8 的 2026-04-20 00:00 → `'2026-04-19T16:00:00Z'`。

**ALB 關鍵欄位解讀：**

| 欄位                     | 值                               | 含義                                            |
| ------------------------ | -------------------------------- | ----------------------------------------------- |
| `target_status_code`     | `-`                              | container 完全無回應，疑似 OOM crash 或重啟     |
| `target_processing_time` | `-1`                             | ALB timeout（> 60s），需查 DB 或下游 bottleneck |
| `elb_status_code`        | `502` + `target_status_code = -` | container crash，非應用層錯誤                   |
| `elb_status_code`        | `504`                            | ALB 等太久，需查 target 耗時                    |

---

## Scan 5: 分級篩選 → 深入分析

**此步驟是掃描與深入分析的橋樑。不要跳過直接寫報告。**

綜合 Scan 1-4 的彙總結果，依以下標準篩選需要深入分析的問題：

**🔴 高（必須深入）：**
- 5xx 連鎖反應（一個服務 503 導致下游多個 endpoint 500）
- `target_status_code = '-'`（container crash）
- 新出現的 error pattern（過去報告中未見過）
- 有使用者可見影響（前端 500、頁面空白、功能失效）

**🟡 中（應該深入）：**
- 彙總 count 前三名的 error 類型
- `target_processing_time > 10s` 的慢請求
- 前後端同時出現的相關錯誤（同一功能的前端 5xx + 後端 error）

**⚪ 低（記錄但不深入）：**
- 已知雜訊（爬蟲、掃描流量，見 Scan 3）
- 已在 `references/known-patterns.md` 或 `context.local.md`（若存在）中標記為「正常行為」的項目
- 數量穩定且無增長趨勢的既有 error

**對每個 🔴 高/🟡 中 問題，執行調查工具箱（`references/investigation-toolkit.md`）取得：**
- 具體的 trace 時序（T2）
- 完整的 exception 內容（T3）
- 程式碼位置與 root cause（T4）
- 若為效能劣化或錯誤爆發，先執行 root cause 追查（T1）

全部完成後，進入產出報告（`references/report-template.md`）。
