---
name: aws-investigate
description: 調查 AWS 線上環境的 error、效能劣化、基礎設施異常。涵蓋 CloudWatch Logs（Insights + FilterLogEvents）、ALB Logs（Athena）、CloudWatch Metrics（Redis/ECS/ALB/RDS）、ECS 容器診斷、CodePipeline 部署比對。支援定期掃描（彙總+篩選+報告）與特定問題調查（trace 追蹤+root cause 分析）兩種入口。
when_to_use: 當使用者提到「查 log」「看 error」「查線上問題」「每週 error 統整」「這個 trace 發生什麼事」「Redis 暴增」「container crash」「ALB 502」「效能變慢」「部署後異常」「寫事件報告」「incident report」時觸發。
argument-hint: "[trace-id, error keyword, or 'scan']"
allowed-tools:
  - Bash(aws *)
  - Bash(python3 *)
  - Bash(nslookup *)
  - Bash(curl *)
  - Bash(gunzip *)
  - Bash(tail *)
  - Bash(git log *)
  - Bash(git diff *)
  - Read
effort: high
---

# AWS Production Investigation

此 skill 內建一套 AWS 託管 Web 應用的調查流程：UTC+8/TWN、Python structlog backend、Nuxt SSR/pino frontend、ASGI/FastAPI exception pattern、Jira ticket 與 3-30-300 事件報告結構。這些是內建經驗，不是唯一做法；若實際專案不同，先依 log、code、config 的觀察結果調整當次查詢與報告。

## Model 使用策略

| 角色 | Model | 原因 |
|------|-------|------|
| 主對話（分析、篩選、分級、報告撰寫） | **Opus** | 需要深度推理、跨領域判斷、綜合多方數據 |
| 查詢 subagent — 簡單查詢（單支查詢、單一 log group） | **Haiku** | 純執行+提取，成本為 Sonnet 的 1/3 |
| 查詢 subagent — 複雜查詢（多支平行、複雜 shell 轉義） | **Sonnet** | Haiku 在複雜 shell 轉義或多 queryId 管理時可能犯錯 |

### Subagent Model 選擇判斷

- 單支查詢 + 單一 log group → **Haiku**
- 2-4 支查詢 + 需要平行管理 queryId → **Sonnet**
- 查詢結果需要初步分類（如區分雜訊 vs 真實 error）→ **Sonnet**

### Context Engineering 核心原則

遵循 **Write / Select / Compress / Isolate** 四步架構，避免 Context Rot（Distraction、Confusion）：

1. **Isolate**：查詢執行一律委派 subagent，作為「上下文防火牆」隔離原始 JSON
2. **Compress**：subagent 在內部消化 raw JSON，**回傳結構化摘要**而非原始結果
3. **Select**：主對話只接收已壓縮的摘要，保留 context 空間給分析和程式碼追蹤
4. **Write**：分析結果寫入報告檔案，不在對話中重複展開

### 查詢委派策略

所有 CloudWatch / Athena 查詢使用 subagent 委派。Subagent 的職責是**執行查詢並壓縮結果**，不做分析判斷。

**Subagent prompt 模板**：

```
執行以下 CloudWatch 查詢，回傳結構化摘要（不要回傳原始 JSON）。

AWS Profile: {profile}
時間範圍: {start_epoch} ~ {end_epoch}

[查詢 1: {描述}]
{完整 aws logs start-query 指令}

[查詢 2: {描述}]
{完整 aws logs start-query 指令}

執行方式：送出所有查詢、等待完成、取回結果。

回傳格式：每支查詢回傳一個摘要表（markdown table），包含：
- 查詢標籤（如 Q1A）
- recordsMatched 數量
- 關鍵欄位的彙總結果（排序後的 top entries）
- 若是取樣查詢：每筆的關鍵欄位值（timestamp、path/namespace、error message 前 200 字元）

不要回傳 raw JSON、@ptr、statistics block、完整 stack trace。
```

**每支 subagent 限 3-4 支查詢**，避免工作量過大導致 stall。需要 5+ 支查詢時，拆成多支 subagent 平行。

### 工作流程分段

入口 A 採漏斗式流程，先以固定 query set 做 Quick Triage，再由使用者決定是否深入。每階段只帶入上一階段的壓縮摘要：

| 階段 | 輸入 | 執行方式 | 輸出 |
| --- | --- | --- | --- |
| **Quick Triage** | 固定 query set + context.local.md | **Haiku** subagent（1 支，query set 見 Step 1） | 錯誤分布概覽 + 已知模式比對 |
| **↕ Checkpoint** | Triage 摘要 | 展示結果，問使用者是否繼續 | 使用者決定 scope |
| Scan 1-2 彙總 | Triage 摘要 + 查詢模板 | Haiku/Sonnet subagent（回傳摘要表） | 錯誤分布摘要（跳過 Step 0） |
| Scan 3 取樣 + 雜訊識別 | 上階段摘要 + 取樣查詢 | Haiku/Sonnet subagent（回傳摘要表） | 每個 error 的分類（雜訊/真實/待查） |
| Scan 5 分級 | 上階段摘要 | **主對話 Opus**（需判斷力） | 🔴 高/🟡 中/⚪ 低 分級清單 |
| T1-T4 深入調查 | 🔴 高/🟡 中 清單 | **主對話 Opus** + 直接 bash | root cause 分析 |
| 產出報告 | 全部摘要 | **主對話 Opus** | `{config.report_dir}/` 檔案 |

### 取樣查詢的 token 節約

取樣查詢（`limit 3~5`）的 `@message` 可能非常大（2-3KB/筆）。在 subagent 的查詢模板中，盡量用 `parse` + `display` 先萃取關鍵欄位：

```
fields @timestamp, @message
| filter ...
| parse @message /"statusCode":(?<code>\d+)/
| parse @message /"message":"(?<msg>[^"]{0,200})"/
| parse @message /"namespace":"(?<ns>[^"]+)"/
| display @timestamp, code, ns, msg
| limit 3
```

若必須看完整 `@message`（如解析複雜巢狀結構），在 subagent 內用 `python3 -c` + `json.loads` 精簡後再摘要回傳，不要直接回傳原始 JSON。

### 不委派的工作（留在 Opus 主 conversation）

- Scan 5 分級篩選（需要判斷力）
- T1-T4 調查工具箱的分析推理（需要理解程式碼和呼叫鏈）
- T4 程式碼追查（需要 Grep / Read 工具 + 對 codebase 的理解）
- 產出報告（需要綜合多方數據）

---

## 關鍵注意事項

以下三點是歷次調查中最常觸發的陷阱，完整版見 `references/analysis-principles.md`：

1. **`parse` 不過濾紀錄**：必須先 `filter` 再 `parse`，否則不匹配的紀錄仍留在結果中，空值組會在 `stats ... by` 產生誤導性的大數字
2. **時間單位混淆**：FilterLogEvents 的 `--start-time`/`--end-time` 是**毫秒**，Insights 的 `--start-time`/`--end-time` 是**秒**。混用會查到空結果
3. **Duration log ≠ 成功**：部分 API caller 在 status code 判斷前就印出 duration log，見到 duration log 不能直接推論「呼叫成功」

---

## 執行前設定

### Phase 0：載入 Config + 專案知識

**Step 1：Config**

檢查 `${CLAUDE_SKILL_DIR}/config.local.yaml` 是否存在：

**存在** → 讀取為 `{config}` 變數，用於後續所有預設值。結構定義見 `${CLAUDE_SKILL_DIR}/config.example.yaml`（含每個欄位的用途註解）。

**Step 2：專案特定知識**

檢查 `${CLAUDE_SKILL_DIR}/context.local.md` 是否存在：

**存在** → 讀取並記住內容。此檔案是 `config.local.yaml` 的補充——config 放結構化設定，這裡放 config 裝不下的自由格式知識：log schema、trace ID 格式、code path 注意事項、已知雜訊 pattern、歷史案例、report convention、issue tracker 慣例、已驗證陷阱等。在後續所有查詢和判讀中都需要參照。

**不存在** → 提議掃描 codebase 建立基礎版。告知使用者：「我可以掃描 codebase 建立 `context.local.md` 的基礎版，記錄 log 格式、已知雜訊等知識，幫助後續調查更精準。要建立嗎？」使用者拒絕則跳過，調查後維護階段會根據調查發現自動建立。

同意後，用 Grep/Read 掃描以下項目：
- Logging config（structlog / pino 設定）→ log 格式、欄位名
- API caller 實作（HTTP client wrapper）→ error log 格式、duration log 位置
- Session 設定（express-session / connect-redis 等）→ Redis key pattern、TTL
- Trace ID 格式（middleware / request context）→ 生成格式、header 名稱
- Log group 對應 → 名稱與實際 tech stack 是否一致
- 報告與追蹤慣例 → issue tracker 欄位、事件報告格式、團隊 owner 標記方式

產出 `context.local.md`，包含三類內容：

1. **Log 格式與操作知識**（影響「怎麼查」）——error log 配對關係、trace ID 格式、欄位存在條件陷阱、API caller 的 duration log 陷阱、log group 名稱 vs 實際 tech stack
2. **已知行為模式**（影響「怎麼判」）——各觀測層（前端 ALB / 後端 ALB / 前端 CW / 後端 CW / Redis）獨立表格，欄位：模式 | 影響範圍 | 判斷 | 說明 | 發現時間
3. **報告與追蹤慣例**（影響「怎麼交付」）——issue tracker 命名、owner 標記、報告固定章節、團隊慣用嚴重度定義

**內建流程不符合時**：不要先要求使用者改設定，也不要假設另一套架構。先用探索查詢、Grep/Read、現有 config 找出實際規則；當某個規則可重複使用時，在調查後更新 `context.local.md`。

---

**Config 不存在時** → 進入首次設定流程：

1. 說明：「這個 skill 需要一些 AWS 環境設定才能查詢。我會先偵測環境，再請你確認——答案會儲存在 `config.local.yaml`，只需要做一次。」

2. **偵測 AWS Profiles**：執行 `aws configure list-profiles`。

3. **AskUserQuestion（第一輪——核心設定）**：
   - AWS profile（radio）：「要用哪個 profile 查詢 production 環境？」顯示偵測到的 profiles 作為選項。
   - Staging profile（radio）：「Staging 環境的 profile？（比對 prod/staging 差異時會用到）」若偵測到的 profiles 中有明顯 staging 名稱可推薦。若專案沒有 staging 環境，選「沒有 staging 環境」。
   - Log group prefix：「Log group 的共同前綴是什麼？（例如 `/app/myservice`，用來找出要掃描的 log groups）」
   - 時區（radio）：預設推薦 UTC+8 / TWN。

4. **偵測 Log Groups + 格式**（用使用者選的 profile 和 prefix）：
   - 執行 `aws logs describe-log-groups` 列出符合的 log groups
   - 用 AskUserQuestion（checkbox）讓使用者確認要掃描哪些 log groups（預設全選）
   - 用 AskUserQuestion 詢問每個選中 log group 的格式：「這些 log groups 分別是什麼格式？（影響查詢語法和欄位名稱）」提供選項：Python structlog / Nuxt SSR (pino) / 其他

5. **偵測 Athena（ALB log 查詢用）**：
   - 執行 `aws athena list-work-groups --profile {profile}`
   - 若偵測到 workgroup：
     a. 只有一個 → 自動選用，告知使用者
     b. 多個 → AskUserQuestion 讓使用者選擇
   - 執行 `SHOW TABLES` 列出可用的 table
   - 用 AskUserQuestion 讓使用者選擇 ALB table：「以下是 Athena 中的 table，哪些是 ALB access log？（用來分析 container crash、慢請求等 CloudWatch 看不到的問題）」
   - 若偵測不到 workgroup 或 table：「你的專案有用 Athena 查詢 ALB log 嗎？若沒有使用，選『沒有使用 Athena』」

6. **AskUserQuestion（第二輪——補充設定）**：
   - Redis key prefix：「Redis 的 key prefix pattern？（追查 Redis memory 暴增時用來辨識 key 來源，例如 `session:`、`cache:` 等）」提供常見 prefix 選項 + 自訂。若專案沒用 Redis，選「沒有使用 Redis」。
   - 相關 codebase repo 路徑：「其他相關的 codebase repo 路徑？（調查中追蹤呼叫鏈常需跨 repo 看程式碼）」選項：自訂輸入。若只有當前 repo，選「只有當前 repo」。答案寫入 config 的 `related_repos` key。

7. 依 `${CLAUDE_SKILL_DIR}/config.example.yaml` 的結構，將所有答案寫入 `${CLAUDE_SKILL_DIR}/config.local.yaml`。
8. **確保報告產出被 gitignore**：檢查 `{config.report_dir}/.gitignore` 是否存在。若不存在，建立內容為 `*` 和 `!.gitignore` 兩行，整個子目錄的產出都不進 git。
9. 告知使用者：「設定已儲存，未來可直接編輯此檔案修改。」

### 快捷入口（帶參數時）

若使用者以 `/aws-investigate <args>` 觸發且帶有參數（`$ARGUMENTS`）：

- 參數含 hex fragment（如 `69dfb888`）或 trace ID 格式 → 作為 trace ID，跳過 Phase 3，直接進入入口 B
- 參數為 `scan`、`weekly`、`report` → 跳過 Phase 3，直接進入入口 A **完整版（自動跳過 checkpoint）**
- 參數為 `quick`、`triage`，或自然語言暗示快速檢查（如「有沒有狀況」「大致看一下」「快速掃一下」） → 跳過 Phase 1-3，用 `{config}` 預設值直接進入入口 A Quick Triage（含 checkpoint）。**前提：`config.local.yaml` 必須存在且含 `log_formats`**，否則 fallback 到 Phase 1-3 互動流程
- 其他參數作為 error keyword 或 endpoint path → 進入入口 B

Phase 1（選 AWS Profile）和 Phase 2（選 Log Group）仍需確認，但可用 `{config}` 中的預設值作為 AskUserQuestion 的推薦選項加速流程。Quick Triage 入口可直接使用預設值跳過確認。

### Phase 1-3：互動式設定

若未帶參數或需要完整設定，分三個 phase 蒐集必要資訊。

#### Phase 1：選擇 AWS Profile

先列出本機已設定的 profile：

```bash
aws configure list-profiles
```

用 AskUserQuestion 讓使用者選擇目標 profile（radio）。推薦 `{config.aws_profiles}` 中的 profile。

> **SSO Token 過期處理**：若執行 AWS 指令時出現 `Token has expired and refresh failed`，執行以下指令重新登入（**不要帶 `--profile`**，SSO session 是共用的）：
> ```bash
> aws sso login
> ```
> 登入後即可繼續使用 `--profile {profile}` 執行後續查詢。

#### Phase 2：探索 Log Groups

用 AskUserQuestion 詢問 log group prefix 或關鍵字，預設建議 `{config.default_log_group_prefix}`。

根據使用者輸入查詢符合的 log groups：

```bash
aws logs describe-log-groups \
  --log-group-name-prefix "{prefix}" \
  --profile {profile} \
  --query 'logGroups[].logGroupName' \
  --output json
```

將查詢結果以 checkbox 呈現讓使用者確認（預設全選）。

#### Phase 3：選擇入口

用 AskUserQuestion 讓使用者選擇（radio）：
- **入口 A：定期掃描**（週報 / 定期健檢）— 彙總所有 error，篩選重要問題後自動深入分析
- **入口 B：特定問題調查**（已知 error、trace ID、或 PM 回報的問題）— 直接進入調查工具箱

選擇後：
- 入口 A → 詢問時間範圍（預設最近 7 天），進入「定期掃描流程」
- 入口 B → 詢問已知資訊（trace ID、錯誤訊息、endpoint、時間範圍等），直接進入「調查工具箱」

---

## 快速導航

| 使用者需求 | 入口 | 需載入的 references |
|-----------|------|-------------------|
| 「有沒有狀況」「大致看一下」「quick scan」 | A：Quick Triage | 無（僅用 config + context.local.md） |
| 「查 log」「看 error」「每週 error 統整」 | A：完整掃描 | `query-basics` → `periodic-scan` → `report-guidelines` + `report-template` |
| 「這個 trace 怎麼了」「查這個 error」 | B：特定問題調查 | `query-basics` → `investigation-toolkit` |
| 「看 ALB」「container crash」 | B → 直接 T1/Scan 4 | `query-basics` → `aws-tools` |
| 「Redis 暴增」「memory 異常」 | B → 直接 T5 | `query-basics` → `investigation-toolkit`(T5) → `aws-tools` → `metrics-charts` |
| 「效能變慢」「部署後異常」 | B → 直接 T1 | `query-basics` → `investigation-toolkit`(T1) → `aws-tools` → `metrics-charts` |
| 「寫事件報告」「incident report」 | 視情境 | `report-guidelines` + `report-template` → `analysis-principles` |
| 「上次報告提到的那個問題」 | B | `query-basics` → `known-patterns` → `investigation-toolkit`（`context.local.md` 已在 Phase 0 載入） |

### 入口 A：定期掃描

入口 A 採漏斗式流程：上次追蹤偵測 → Quick Triage → Checkpoint → 完整掃描。預設在 Checkpoint 暫停，由使用者決定是否深入。

#### Step 0：掃描參數確認

從使用者自然語言擷取掃描區間，未指定則預設 7 天。同時偵測 `{config.report_dir}/` 目錄中是否有該區間內的定期掃描報告。

用 **一次 AskUserQuestion** 列出建議值讓使用者確認或調整：
- **掃描區間**：建議值 = 使用者指定或預設 7 天
- **上次追蹤**：
  - 偵測到報告 → 建議「比對 {檔名}」（Recommended）
  - 未偵測到 → 選項：提供檔案路徑 / 擴展時間範圍為 2 倍區間（一次查詢涵蓋兩期）/ 跳過

選擇「擴展時間範圍」時，後續所有查詢的時間範圍改為 2 倍區間。上次追蹤的比對只做簡單確認——上次報告的行動項目在本次是否仍存在、量體升降——不對上次做深入調查。

#### Step 1：Quick Triage（不載入 references）

**前提**：`config.local.yaml` 必須存在且含 `log_formats`。不存在時跳過 Quick Triage，fallback 到 Phase 1-3 互動流程再進 Step 3 完整掃描。

用 **1 支 Haiku subagent** 執行以下固定 query set。時間範圍為 Step 0 決定的範圍。

**Log group 選擇**：從 `{config.log_formats}` 取所有 log groups，按格式類型分組。同格式的 log groups 合併到同一個 Insights 查詢（CloudWatch Insights 支援多 log group）。

**Group-by 欄位**：依格式類型對應內建預設——`python_structlog` 用 `event`、`nuxt_ssr` 用 `namespace`。格式不明時用通用 fallback：`substr(@message, 0, 120)`。

**Query set**（每種格式各一組）：

| 查詢 | Log Groups | Query |
| --- | --- | --- |
| 分布 | 該格式所有 log groups | `fields {group_by} \| filter level = "error" \| stats count(*) as cnt by {group_by} \| sort cnt desc \| limit 20` |
| 每日趨勢 | 該格式所有 log groups | `fields @timestamp \| filter level = "error" \| stats count(*) as cnt by bin(1d) as day \| sort day asc` |

**結果異常處理**：若任何查詢 `recordsMatched = 0` 或 group-by 結果全為空值，可能是欄位名稱不符。提示使用者確認 log 格式設定，或執行完整掃描（含探索查詢）。

**recordsMatched 與 top 20 的差距**：若 top 20 的 count 加總遠小於 recordsMatched，表示大量 error 有 unique event string（如含 UUID、request path 的 middleware log），被 group-by 稀釋。此時需在完整掃描 Scan 1 中用排除法或 `parse` 萃取 event 前綴重新分群。

取得 subagent 回傳的摘要後，在主對話中執行：

1. 比對 `context.local.md` 已知模式（若存在），標記每個 error 為「已知雜訊」「已知正常」「需關注」「未知（需調查）」。無 `context.local.md` 時跳過比對，直接展示原始分布
2. 從每日趨勢辨識 spike 或異常成長
3. 產出摘要表呈現給使用者，含判斷依據

#### Step 2：Checkpoint

展示 Quick Triage 摘要後，問使用者：

> 以上是 error 概覽。要怎麼處理？
> - **繼續完整掃描**（Scan 1-5 + 調查，需載入 references）
> - **只追查特定項目**（指定後進入調查工具箱）
> - **存成簡易報告後結束**（把摘要寫成 `{config.report_dir}/` 檔案留紀錄，方便日後比較）
> - **到這裡就夠了**（不存檔，對話摘要即產出）

選擇「存成簡易報告」時，將 Quick Triage 摘要（error 分布表 + 每日趨勢 + 已知模式比對結果）寫入 `{config.report_dir}/YYYY-MM-DDTHHMM-triage.md`，不需要載入 `references/report-template.md`，格式從簡。

**自動跳過 checkpoint 的條件**：快捷入口參數為 `scan`、`weekly` 或 `report` 時，自動選擇「繼續完整掃描」。

#### Step 3：完整掃描（使用者確認後才進入）

進入此階段前，依序讀取：
1. `references/query-basics.md` — Log 格式、CLI 操作、查詢工具選擇
2. `references/periodic-scan.md` — Scan 1-5 完整流程

**Quick Triage 的結果直接作為 Scan 1 Step 0 的輸出**——從 Scan 1 第一層（外部 API 呼叫失敗）開始，跳過 Step 0 探索查詢，避免重複。

完成 Scan 5 篩選後，對 🔴 高/🟡 中 問題：
3. `references/investigation-toolkit.md` — T1-T4 調查工具箱

產出報告時：
4. `references/report-guidelines.md` — 撰寫原則與風格指引
5. `references/report-template.md` — 報告模板（純結構）
6. `references/analysis-principles.md` — 判讀原則與驗證守則

視需要參考：
- `references/aws-tools.md` — AWS 診斷工具速查
- `references/known-patterns.md` — 跨組織通用的已知行為模式
- `references/metrics-charts.md` — Metrics 圖表產生（涉及基礎設施指標時）

> `context.local.md` 已在 Phase 0 載入，不需要在此階段重複讀取。

### 入口 B：特定問題調查

進入此流程前，依序讀取：
1. `references/query-basics.md` — Log 格式、CLI 操作、查詢工具選擇
2. `references/investigation-toolkit.md` — T1-T4 調查工具箱

完成調查後（視需要）：
3. `references/report-guidelines.md` — 撰寫原則
4. `references/report-template.md` — 報告模板
5. `references/known-patterns.md` — 比對已知行為
6. `references/metrics-charts.md` — 產圖附在報告中

> `context.local.md` 已在 Phase 0 載入，不需要在此階段重複讀取。

---

## 報告補完互動（技術調查完成後、產出最終報告前）

AI agent 能查到技術根因和指標，但有些資訊只有人知道。在產出最終報告前，用 AskUserQuestion 向使用者收集以下資訊。所有收集到的資訊直接寫入最終報告，報告產出後不預期有人回來更新。

### 1. 使用者影響（AI 查不到）

- 使用者感受到什麼？（頁面變慢 / 功能中斷 / 完全無法使用）
- 影響範圍？（全部使用者 / 特定條件 / 百分比）
- 有客訴嗎？大約幾件？
- 有營收或業務指標影響嗎？

使用者回答「不確定」或「沒有」的項目不放進報告。

### 2. 系統性根因（AI 查不到）

- 這個問題有沒有可能在更早的階段被發現？（code review / 測試 / 監控）
- 是什麼流程缺口讓它到了線上才爆發？
- 有沒有類似的風險可能存在於其他地方？

使用者若說「目前沒想到」，報告就只保留技術根因，不硬塞。

### 3. Action Items 審核

- 哪些建議要採用？哪些不適用或需要調整？
- 建議負責方是否正確？
- 有 Jira 或 issue tracker 單號嗎？
- 有沒有要調整優先序或新增項目？

採用的項目寫入行動清單（附上使用者提供的追蹤資訊），未採用的不放進報告。

---

## 報告自檢（報告完成後、提交使用者前執行）

### Pass 1：完整性
- [ ] 每個 🔴 高/🟡 中 問題六面向齊全：情境/錯誤流程/root cause/用戶影響/潛在議題/建議
- [ ] 每個數據聲明可追溯到查詢來源（`[Qn]` 標記位置規則見 `report-guidelines.md`「數據與來源」）
- [ ] 行動清單每行 6 欄位齊全（欄位定義見 `report-guidelines.md`「行動清單」；追蹤欄在互動階段後補完）
- [ ] 查詢來源 `<details>` 內每個 Qn 都有完整 CLI 指令可重現
- [ ] 報告路徑正確：`{config.report_dir}/YYYY-MM-DDTHHMM.md`
- [ ] 涉及基礎設施指標異常的 🔴 高/🟡 中 附 CloudWatch 圖表（PNG），存放於 `{config.report_dir}/assets/{basename}/`

### Pass 2：正確性
- [ ] 🔴 高/🟡 中 的 root cause 分析有 Grep/Read 程式碼證據支撐，非推測（見 `analysis-principles.md`「驗證守則」）
- [ ] 「扣除雜訊後」的數字計算邏輯正確（去重、排除爬蟲）
- [ ] ASCII flow 中的系統元件名稱與實際 log group 一致
- [ ] 敏感資訊（token、secret、client_secret）已遮蔽
- [ ] 若發現已知行為已被修復，行動清單加入 `[維護] 更新 context.local.md：標記 {pattern} 為 [已修復 YYYY-MM]`

### Pass 3：可讀性（原則見 `report-guidelines.md`）
- [ ] 3-30-300 分層：不展開任何東西的讀者就能做決策
- [ ] Executive Card 只包含事實和已決定的事，沒有未經團隊決策的時程或承諾
- [ ] Action Items 明確標示為初步建議（Proposed），沒有把 AI 建議寫成團隊已定案的決策
- [ ] 格式：「發生什麼事」用 bullet points、「為什麼會這樣」和「排除的假設」用表格，不是整段散文
- [ ] 語氣為 Professional Plain Language（Knowledgeable Friend），不是書面腔或過度口語
- [ ] DRY：同一事實只在一個 section 出現
- [ ] 精簡結構：「發生什麼→為什麼→怎麼辦」，不是調查過程的流水帳
- [ ] Flexible Template：只保留適用的 section，不適用的直接省略，不硬湊字數
- [ ] 技術細節與主要敘事分離：逐行 code reference、查證段落、完整查詢指令不在報告本文
- [ ] 語言精準：混合結果用限定語、不同觀測層數據不混行（見 `analysis-principles.md`）
- [ ] 報告文字預設台灣正體中文；使用者指定其他語言時從之

---

## 調查後維護

報告完成並通過自檢後，檢查是否有新知識需要更新 `context.local.md`：

- 發現新的 error pattern 或 log 格式陷阱 → 新增到「Log 格式與操作知識」
- 確認某個 error 是固定雜訊（本次掃描期間內每天穩定出現、量體無異常波動、不需人工關注）→ 新增到對應觀測層的「已知行為模式」表格，**含精確的排除條件**（filter pattern / status code / path 等），讓未來掃描在查詢層直接排除以節省 token 與查詢費用。排除條件不確定時問使用者確認
- 發現已知行為已被修復 → 標記為 `[已修復 YYYY-MM]`
- 發現 log group 名稱與 tech stack 不一致 → 記錄對應關係
- 發現專案穩定規則（log schema、trace ID、報告欄位、issue tracker 慣例）→ 新增到對應章節

若 `context.local.md` 不存在，自動建立——依 Phase 0 Step 2 的章節結構寫入本次調查發現的內容。
