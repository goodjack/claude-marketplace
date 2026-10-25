# 查詢基礎（共用參考）

## 查詢工具選擇

根據查詢目的選擇最經濟的工具：

| 目的 | 工具 | 計費 | 原因 |
|------|------|------|------|
| 彙總統計（count、avg、分布） | **Insights** | $0.005/GB scanned | 唯一支援 stats 語法 |
| 跨 log group 搜尋 | **Insights** | $0.005/GB scanned | FilterLogEvents 不支援跨 group |
| 已知 keyword 精確查找（trace ID、UUID） | **FilterLogEvents** | **免費** | 精確匹配足夠，無 scan 費用 |
| 取少量完整 log（exception、stack trace） | **FilterLogEvents** | **免費** | 精確匹配足夠 |
| ALB log 分析 | **Athena** | $5/TB scanned | ALB log 在 S3，只能用 Athena |
| 時間序列分布（bin(1h)、趨勢） | **Insights** | $0.005/GB scanned | 需要 stats by bin() |

執行 Insights 或 Athena 前，先確認 AWS profile、時間範圍、log groups 或 tables；已知 trace ID、UUID 或明確 keyword 時，優先用 FilterLogEvents 精確查找。

**FilterLogEvents 使用注意：**
- `--start-time` / `--end-time` 單位是**毫秒**（Insights 用秒）
- 每次最多回傳 1MB / 10,000 筆，有 `nextToken` 要分頁
- 帳號級 **5 TPS 硬限**——不要平行送出太多
- 不支援 Infrequent Access log class
- **不支援跨 log group 查詢**——需要跨 group 時改用 Insights

**FilterLogEvents 基本語法：**

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} \
  --end-time {end_epoch_ms} \
  --filter-pattern '"{keyword}"' \
  --profile {profile} --output json
```

JSON 格式 log 可用進階語法：`--filter-pattern '{ $.field = "value" }'`

---

## Log 格式差異

不同 tech stack 的 log 格式不同，查詢條件要分開處理。以下以 Python structlog + Nuxt SSR 為例，其他框架請依實際格式調整：

> 這是內建範例的 log 格式。若實際專案不同，先用探索查詢找出實際欄位與錯誤訊號。

| 欄位        | Python backend（structlog）                           | Nuxt SSR 前端（pino）                                       | 判讀提示 |
| ----------- | ----------------------------------------------------- | ----------------------------------------------------------- | -------- |
| log level   | `level = "error"` / `"warn"` / `"info"`               | `level = "error"` / `"warn"` / `"info"`                     | 大多數框架通用 |
| 時間        | `timestamp`                                           | `time`                                                      | 欄位名稱因框架而異 |
| 模組來源    | `logger`（Python module path）                        | `namespace`（如 `myapp:server:services:SomeApi`）            | 追查程式碼位置的關鍵 |
| HTTP 狀態碼 | event string 中（如 `status is 503`）                 | 巢狀在 `err.data.statusCode`（需用 `@message like` 搜尋）   | 巢狀欄位無法直接 filter |
| exception   | `exc_info`（array：class、message、traceback_object） | `err.msg`、`err.type`                                       | 取完整 exception 的關鍵 |
| trace ID    | `amz_trace_id`（獨立欄位）                            | `config.headers.X-Amzn-Trace-Id`（巢狀在 log body）         | 跨服務追蹤必備 |

> **重要**：Log group 與系統元件的對應關係，參見 `config.local.yaml` 的 `log_formats` 設定。Log group 名稱可能誤導——例如名稱暗示後台管理的 log group，實際上可能是 SSR 前端而非後端服務，查詢語法要依實際格式而非名稱判斷。
>
> **其他 stack**：不同框架的 log 欄位名稱和結構差異很大。首次使用時建議先用 `fields @message | filter level = "error" | limit 5` 觀察實際格式，再依實際欄位調整查詢。

---

## Log Level 判讀策略

不同 tech stack 的 level 命名不統一（Python structlog 用 `"warn"`，某些 Nuxt 版本用 `"warning"`，也可能有 `"debug"`、`"fatal"` 等）。

**每次查詢前，先 group by level 了解實際分布，再決定查詢範圍：**

```
fields level
| stats count() as cnt by level
| sort cnt desc
```

根據分布，依以下優先序查詢：

| 優先序 | Level              | 典型用途                           | 何時查                                   |
| ------ | ------------------ | ---------------------------------- | ---------------------------------------- |
| 1      | `error`            | 例外、系統失敗、外部服務呼叫失敗   | 每次必查                                 |
| 2      | `warn` / `warning` | 業務邏輯異常、可恢復情境、降級行為 | 定期抽查；`error` 量少時可能才是主要訊號 |
| 3      | `info`             | 正常業務流程記錄                   | 特定問題追蹤時作流程脈絡輔助             |
| 4      | `debug`            | 詳細除錯訊息                       | 通常不查                                 |

**何時要加查 `warn`：**
- `error` 數量明顯下降但系統感覺不對 → warn 可能在悄悄累積
- 懷疑功能降級（cache miss、fallback 觸發）但 error log 沒有反映
- 追蹤 OIDC、session、認證相關問題（這類問題常用 warn 而非 error）
- 追查後確認某類 `error` 應降為 `warn`，之後要用 warn 才找得到

**擴大掃描（error + warn 同時看）：**

```
fields @timestamp, level, namespace, @message
| filter level in ["error", "warn"]
| parse @message /"msg":"(?<msg>[^"]+)"/
| stats count() as cnt by level, namespace, msg
| sort cnt desc
| limit 50
```

---

## Insights CLI 操作

查詢為兩步驟：先 `start-query` 取得 queryId，等幾秒後 `get-query-results` 取結果。

```bash
aws logs start-query \
  --log-group-name "{log_group}" \
  --start-time {start_epoch} \
  --end-time {end_epoch} \
  --query-string '...' \
  --profile {profile} --output json

# 等 5~10 秒後取結果
aws logs get-query-results --query-id "{query_id}" --profile {profile} --output json
```

時間戳記用 Python 計算：

```python
import time
# 最近 7 天
start = int(time.time() - 7 * 24 * 3600)
end = int(time.time())
# 特定時段（依 config.timezone.offset_hours 換算）
from datetime import datetime, timezone, timedelta
tz = timezone(timedelta(hours={config.timezone.offset_hours}))
start = int(datetime(2026, 4, 16, 0, 10, 0, tzinfo=tz).timestamp())
end   = int(datetime(2026, 4, 16, 0, 11, 0, tzinfo=tz).timestamp())
```

跨 log group 同時查詢：

```bash
aws logs start-query \
  --log-group-names "{log_group_1}" "{log_group_2}" \
  --start-time {start_epoch} --end-time {end_epoch} \
  --query-string '...' \
  --profile {profile} --output json
```

> **平行送出多支查詢**：`start-query` 是非同步的，可以一次送出所有查詢，記下所有 queryId，再一起等待取結果，大幅節省時間。

> **Shell 轉義注意**：`--query-string` 使用單引號包裹時，內部若含單引號（Python repr 格式：`'path': '/api/...'`），需用 `'\''` 轉義，或改用雙引號包裹外層。

> **等待時間**：查詢非同步，依資料量調整——小範圍（1 小時）等 5 秒，跨天範圍等 8-10 秒。status 不是 `Complete` 就再等。

---

## 查詢失敗處理

| 狀態 | 處理 |
|------|------|
| `status: Failed` / `Cancelled` | 記錄錯誤訊息，用更小的時間範圍重試 |
| `recordsMatched: 0` | 不代表沒問題——確認 log group 和時間範圍是否正確，再試一次 |
| `status: Running` 超過 30 秒 | 取消查詢，縮小範圍或減少 log group 數量後重試 |
| SSO Token 過期（`Token has expired and refresh failed`） | 執行 `aws sso login`（**不帶 `--profile`**，SSO session 是共用的；設定檔有多個 `sso-session` 時用 `--sso-session {name}` 指定），登入後繼續 |
| `LimitExceededException` | 等 5 秒再重試（CloudWatch 同時查詢數上限） |
| FilterLogEvents `ThrottlingException` | 等 2 秒 + exponential backoff（5 TPS 硬限） |
| `ResourceNotFoundException`（StartQuery） | log group 不在這個帳號或區域；先用 `describe-log-groups` 確認再查 |
| `InvalidParameterException`：`logGroupNames` 長度限制 | 一支 Insights 查詢最多 50 個 log group，分批送 |
| `MalformedQueryException: token recognition error at '\'` | 跳脫字元在組字串時被吃掉或多加；Python 組查詢用 raw string |
| `MalformedQueryException: Ephemeral field is already defined` | 同一支查詢裡 `parse` 或 `fields ... as` 把同一個欄位名稱定義了兩次，改名 |

---

## 執行環境陷阱（macOS／zsh／S3／Athena／時區）

歷次調查反覆撞到、而且錯誤訊息不會直接指出原因的坑。

**zsh**（macOS 預設 shell，Bash 工具也跑在 zsh）：
- **不會自動拆字**：`P="--profile x --region y"; aws ... $P` 會變成一個參數，回 `Unknown options`；`for x in "a b"; do set -- $x` 同樣失效。改用陣列 `P=(--profile x --region y); aws ... "${P[@]}"`、`${=x}`，或直接 `export AWS_PROFILE=x AWS_REGION=y`。
- 指令中出現 `==` 或 `=====` 開頭的字（例如 `echo == $p`）會被當成指令路徑展開，回 `= not found`；加引號。
- `*.gz(N)` 這類 glob 修飾在非互動執行不可靠；列檔改用 `find` 或 Python。

**macOS 工具差異**：
- 沒有 `timeout`（有裝 coreutils 才有 `gtimeout`）；長指令改成背景執行。
- `zcat` 對 `.gz` 會去找 `.Z` 而失敗，錯誤若被 `2>/dev/null` 藏起來就變成「比對 0 筆」的假陰性；一律用 `gzip -dc`。
- BSD `grep` 沒有 `-P`；用 `grep -E`、`rg` 或 Python。
- `date` 用 `-v-1d`，不是 GNU 的 `-d`；換算時間戳記用 Python（見上方「Insights CLI 操作」）。

**Python 與憑證**：
- 系統 Python 通常沒有 boto3，awscli 自帶的 Python 也 import 不到 botocore；用 `uv run -q --with boto3 python -I script.py`，憑證交給 `AWS_PROFILE`。
- 不要讀 `~/.aws/sso/cache` 或 `aws configure export-credentials` 把憑證寫成檔案：沒必要，Claude Code 的自動模式也會擋下。
- 無人值守的排程或長時間監看：SSO token 過期後每次查詢都會失敗，要偵測到就停下並通知，不要一直記 FAIL。

**AWS CLI 與 JMESPath**：
- 欄位可能是 null 時，`starts_with()`、`length()` 會報 `invalid type for value: None`；先判斷存在：`Functions[?Runtime && starts_with(Runtime, 'nodejs')]`。
- 跑超過兩分鐘的迴圈（逐一列 cluster、逐區域掃描）直接背景執行並寫進度檔；等待查詢完成用 `until` 迴圈輪詢 status，不要單獨 `sleep`。

**S3 下載大量 log**（CloudFront、WAF、CloudTrail 這類每小時好幾個檔、累積多年的 bucket）：
- `aws s3 ls --recursive`、`--summarize`、`aws s3 cp --recursive --exclude "*" --include "X*"` 都會先列出整個 prefix，多年份 bucket 要跑好幾分鐘甚至逾時。
- 改用精確到小時的 prefix 列檔，再平行下載：

```bash
aws s3api list-objects-v2 --bucket {bucket} --prefix "{prefix}/{dist_id}.{YYYY-MM-DD}-{HH}." \
  --query 'Contents[].Key' --output text --profile {profile} | tr '\t' '\n' \
  | xargs -P 16 -I{} aws s3 cp "s3://{bucket}/{}" {local_dir}/ --only-show-errors --profile {profile}
```

**Athena**：
- 依掃描量計費（約 5 美元／TB）；查詢一定帶分區條件，沒分區的表不要直接查。
- 回 `No output location provided`：用 `aws athena get-work-group` 看 workgroup 有沒有設定結果位置；有些 workgroup 強制使用自己的設定，用戶端指定的會被覆蓋。
- 分區範本可能指錯資料夾，查出 0 筆也不報錯。查前用 `aws glue get-table` 核對 `storage.location.template`（partition projection）或分區位置，跟 `aws s3 ls` 看到的實際資料夾比對。
- 轉到 Glacier 類儲存的物件 Athena 會直接略過、不報錯；查舊資料前用 `aws s3api get-bucket-lifecycle-configuration` 確認轉存天數。

**時區**：
- WAF `timestamp` 是 UTC 毫秒；CloudFront 檔名的小時與紀錄時間是 UTC；CloudTrail `eventTime` 是 UTC；Insights 的時間參數是秒、FilterLogEvents 是毫秒。
- 當地時間的「某一天」換成 UTC 可能跨兩天（UTC+8 的一整天是前一天 16:00 到當天 16:00 UTC），分區條件要涵蓋兩個 UTC 日。

---

## Subagent 回傳格式模板

委派原則與每支 subagent 的查詢數量上限見 `SKILL.md`「查詢委派策略」，此處只放 prompt 模板與回傳格式本體。

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

---

## Trace ID 查詢模式

前提：`config.trace_id` 已設定。未設定時跳過所有 trace 相關查詢。

### 已知 Trace ID 追蹤

用 FilterLogEvents（免費）精確查找特定 trace：

```bash
aws logs filter-log-events \
  --log-group-name "{log_group}" \
  --start-time {start_epoch_ms} --end-time {end_epoch_ms} \
  --filter-pattern '"{trace_fragment}"' \
  --profile {profile} --output json
```

> `trace_fragment` 長度由 `config.trace_id.search_fragment_length` 決定（預設 8 hex chars），確保唯一性的同時減少搜尋成本。

### Trace Discovery（從 error 反查 trace ID）

從已知 error 群集中取樣，萃取 trace ID 做去重和跨層關聯：

```
fields {config.trace_id.backend_field}, event, logger
| filter level = "error" and event like /{error_keyword}/
| limit 10
```

### Trace-Based 去重

同一個 request 可能產生多筆 log（如 uvicorn.error + fastapi.routes）。用 `count_distinct` 對比：

```
fields {config.trace_id.backend_field}
| filter level = "error" and event like /{error_keyword}/
| stats count(*) as log_count, count_distinct({config.trace_id.backend_field}) as unique_requests
```

`log_count / unique_requests` = double-logging 倍率。報告以 unique_requests 為基準。

### 跨前後端 Trace 關聯

用 trace fragment 跨 log group 驗證前後端是否對應同一個 request：

```bash
# 後端取 trace ID fragment
# 再用 fragment 搜尋前端 log group
aws logs filter-log-events \
  --log-group-name "{frontend_log_group}" \
  --start-time {start_epoch_ms} --end-time {end_epoch_ms} \
  --filter-pattern '"{trace_fragment}"' \
  --profile {profile} --output json
```

> 前端 log 的 trace ID 通常巢狀在 `@message` 中（如 `config.headers.X-Amzn-Trace-Id`），用 `config.trace_id.frontend_pattern` 定位。
