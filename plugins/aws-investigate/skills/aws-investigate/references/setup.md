# 設定檔不存在時

SKILL.md Phase 0 在 `~/.claude/aws-investigate/` 與目前版本的 skill 目錄都找不到本機檔時才用這份：先從舊版本搬移，找不到才跑首次設定。新檔一律寫到 `~/.claude/aws-investigate/`：plugin 升版後安裝目錄會換，寫在 skill 目錄裡的檔案會跟著失聯。

## 從舊版本搬移

plugin 快取裡每個版本各有一份 skill 目錄，舊版本的 `config.local.yaml` 與 `context.local.md` 留在舊版本的資料夾裡。設定檔與專案知識一起處理；從 Step 2 進來時只處理 `context.local.md`。

1. 列出候選。版本資料夾位在 `~/.claude/plugins/cache/<marketplace>/aws-investigate/<版本>/skills/aws-investigate/`，兩層都用萬用字元找；也用相對寫法 `${CLAUDE_SKILL_DIR}/../../../*/skills/aws-investigate/` 找一次，涵蓋設定目錄不在 `~/.claude` 的情況。排除目前版本自己的 `${CLAUDE_SKILL_DIR}`（Phase 0 已經查過）。
2. 一份都沒有 → 跳到下方「首次設定流程」（從 Step 2 進來時回到 Step 2 的「不存在」）。
3. 只有一份 → 告知來源版本與路徑，使用者同意後複製到 `~/.claude/aws-investigate/`（目錄不存在就先建立）。
4. 有多份 → 列出每份的版本、路徑與修改時間，請使用者選。設定檔與 `context.local.md` 各選一份，預設選同一個版本資料夾。
5. 新位置已經有同名檔時，不複製那一份、不覆寫，告知使用者保留的是新位置的版本。
6. 用複製而不是移動：舊版本資料夾之後會被 plugin 清理一併移除，留著不影響。複製完回到 SKILL.md Phase 0，從新位置讀取。

## 首次設定流程

1. 說明：「這個 skill 需要一些 AWS 環境設定才能查詢。我會先偵測環境，再請你確認——答案會儲存在 `~/.claude/aws-investigate/config.local.yaml`，只需要做一次。」

2. **偵測 AWS Profiles**：執行 `aws configure list-profiles`。

3. **AskUserQuestion（第一輪——核心設定 + repo 路徑）**：
   - AWS profile（radio）：「要用哪個 profile 查詢 production 環境？」顯示偵測到的 profiles 作為選項。
   - Staging profile（radio）：「Staging 環境的 profile？（比對 prod/staging 差異時會用到）」若偵測到的 profiles 中有明顯 staging 名稱可推薦。若專案沒有 staging 環境，選「沒有 staging 環境」。
   - Log group prefix：「Log group 的共同前綴是什麼？（例如 `/app/myservice`，用來找出要掃描的 log groups）」
   - 時區（radio）：預設推薦 UTC+8 / TWN。
   - 相關 codebase repo 路徑：「其他相關的 codebase repo 路徑？（我會掃描程式碼自動偵測 log 格式、trace ID、Redis 等設定值）」選項：自訂輸入。若只有當前 repo，選「只有當前 repo」。

4. **偵測 Log Groups + 格式**（用使用者選的 profile 和 prefix）：
   - 執行 `aws logs describe-log-groups` 列出符合的 log groups
   - 用 AskUserQuestion（checkbox）讓使用者確認要掃描哪些 log groups（預設全選）
   - 用 AskUserQuestion 詢問每個選中 log group 的格式：「這些 log groups 分別是什麼格式？（影響查詢語法和欄位名稱）」提供選項：Python structlog / Nuxt SSR (pino) / 其他

5. **Codebase 掃描自動偵測**：用 Grep/Read 掃描當前 repo + 使用者提供的 related_repos，偵測以下設定的建議值：

   | 偵測目標 | 掃描方式 | 對應 config 欄位 |
   |---------|---------|-----------------|
   | Error type 欄位 | logging config（structlog 的 `exc_info`、pino 的 `err.type`） | `error_type_field` |
   | Trace ID | middleware / request context / header 設定 | `trace_id.*` |
   | Redis key pattern | Redis client usage（prefix、key 模板） | `redis_key_prefixes` |
   | Error keywords | error handler / exception logger 實作 | `backend_error_keywords` |

   此步驟與 Phase 0 Step 2（context.local.md 生成）共用掃描邏輯——差異在於首次設定將結果寫入 config，後續調查則寫入 context.local.md。未偵測到的欄位留空，使用者可手動填寫或在後續調查中動態探索。

6. **偵測 Athena（ALB log 查詢用）**：
   - 執行 `aws athena list-work-groups --profile {profile}`
   - 若偵測到 workgroup：
     a. 只有一個 → 自動選用，告知使用者
     b. 多個 → AskUserQuestion 讓使用者選擇
   - 執行 `SHOW TABLES` 列出可用的 table
   - 用 AskUserQuestion 讓使用者選擇 ALB table：「以下是 Athena 中的 table，哪些是 ALB access log？（用來分析 container crash、慢請求等 CloudWatch 看不到的問題）」
   - 若偵測不到 workgroup 或 table：「你的專案有用 Athena 查詢 ALB log 嗎？若沒有使用，選『沒有使用 Athena』」

7. **AskUserQuestion（第二輪——確認自動偵測結果）**：展示 step 5 偵測到的建議值，請使用者確認或修改：
   - Redis key prefix：若偵測到則預填，否則手動。「Redis 的 key prefix pattern？」若專案沒用 Redis，選「沒有使用 Redis」。
   - Backend error keywords：若偵測到則預填（如 `occur ERROR`、`Exception in ASGI`），否則手動。
   - Error type 欄位：若偵測到則預填（如 `python_structlog: exc_info.0`），否則留空（掃描時動態探索）。
   - Trace ID 設定：若偵測到則顯示建議值（如 `backend_field: amz_trace_id`），否則提供「未使用 trace ID」選項。

8. 依 `${CLAUDE_SKILL_DIR}/config.example.yaml` 的結構，將所有答案寫入 `~/.claude/aws-investigate/config.local.yaml`（目錄不存在就先建立）。
9. **確保報告產出被 gitignore**：檢查 `{config.report_dir}/.gitignore` 是否存在。若不存在，建立內容為 `*` 和 `!.gitignore` 兩行，整個子目錄的產出都不進 git。
10. 告知使用者：「設定已儲存在 `~/.claude/aws-investigate/config.local.yaml`，未來可直接編輯此檔案修改。」
