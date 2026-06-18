# aws-investigate

一個 Claude Code plugin skill，用於調查 AWS 線上環境問題——error、效能劣化、基礎設施異常。

## 功能

- **定期掃描**：彙總 CloudWatch Logs、ALB logs（Athena）、基礎設施指標的錯誤，產出分級報告
- **特定問題調查**：透過 trace ID 追蹤個別 error、分析 exception 內容、追查 root cause 到程式碼
- **自動報告產出**：產出 3-30-300 progressive disclosure 結構的事件報告

### 支援的 AWS 服務

| 服務 | 工具 | 用途 |
| --- | --- | --- |
| CloudWatch Logs | Insights + FilterLogEvents | 應用層 error 分析 |
| ALB Access Logs | Athena | 網路層異常偵測 |
| CloudWatch Metrics | get-metric-statistics | 基礎設施健康監控 |
| ECS | describe-tasks/services | Container crash 診斷 |
| CodePipeline | list-pipeline-executions | 部署關聯比對 |
| ElastiCache (Redis) | Metrics + CLI | Memory 暴增調查 |

## 安裝

### 透過 Marketplace 安裝（推薦）

先加入 marketplace（若尚未加入）：

```
/plugin marketplace add goodjack/claude-marketplace
```

安裝 plugin：

```
/plugin install aws-investigate@goodjack-claude-marketplace
```

### 手動安裝

若要從本機 checkout 安裝 plugin，請把整個 marketplace repo 加入 Claude Code，再安裝其中的 `aws-investigate` plugin：

```bash
git clone https://github.com/goodjack/claude-marketplace.git
cd claude-marketplace
```

在 Claude Code 中執行：

```
/plugin marketplace add .
/plugin install aws-investigate@goodjack-claude-marketplace
```

不建議只複製 `skills/aws-investigate/` 到 skills 目錄，因為這會跳過 plugin manifest 與 marketplace metadata。

## 首次設定

第一次使用時，skill 會引導你完成互動式設定，產出 `config.local.yaml`：

1. **AWS profiles** — production/staging 使用哪些 CLI profile
2. **Log group prefix** — CloudWatch log group 探索用的預設前綴
3. **Log 格式對應** — 哪些 log group 使用 Python structlog、哪些用 Nuxt SSR
4. **Athena 設定** — workgroup、ALB table 名稱（選填）
5. **Redis key prefix** — Redis memory 調查用的 key 前綴（選填）
6. **時區** — 報告時間顯示

你也可以手動複製 `config.example.yaml` 為 `config.local.yaml` 並編輯。

## 使用方式

### 透過 Slash Command 呼叫

```
/aws-investigate scan          # 定期掃描（最近 7 天）
/aws-investigate 69dfb888      # 用 trace ID 追蹤特定請求
/aws-investigate "timeout"     # 調查特定 error keyword
```

### 或讓 Claude 自動偵測

直接描述你想調查的問題：
- 「查一下這週的 production error」
- 「這個 trace ID 69dfb888 發生什麼事？」
- 「Redis memory 在暴增，幫我查」
- 「寫一份 502 error 的事件報告」

## 設定檔

### `config.local.yaml`

儲存你的環境特定設定。**已加入 .gitignore**，不會意外 commit 敏感資訊。

欄位說明見 `config.example.yaml`。

### `context.local.md`

`config.local.yaml` 的補充——config 放結構化設定，這裡放 config 裝不下的自由格式知識：log 格式陷阱、trace ID 格式、code path 注意事項、已知雜訊 pattern、歷史案例等。Skill 在 Phase 0 載入此檔案，由 AI 在調查過程中主動維護。

此檔案為**選填**——首次使用時 skill 會提議掃描 codebase 建立基礎版，之後在每次調查中持續更新。沒有它 skill 仍可正常運作，但有了它調查效率會持續提升。

內建調查流程使用 TWN/UTC+8、Python structlog、Nuxt SSR/pino、ASGI/FastAPI、Jira ticket 與 3-30-300 事件報告結構。若實際專案不同，agent 會先依 log / code / config 觀察結果調整當次調查，並把穩定規則記錄到 `context.local.md`。

## 檔案結構

```
aws-investigate/
├── SKILL.md                    # 主 skill 指引
├── config.example.yaml         # 設定範例（附說明）
├── config.local.yaml           # 你的本地設定（git-ignored）
├── context.local.md            # 專案特定知識（git-ignored，AI 維護）
├── .gitignore
├── README.md
└── references/
    ├── query-basics.md         # CloudWatch 查詢基礎
    ├── periodic-scan.md        # Scan 1-5 完整流程
    ├── investigation-toolkit.md # T1-T5 深入調查工具
    ├── known-patterns.md       # 跨組織通用的已知行為
    ├── aws-tools.md            # AWS 診斷工具速查
    ├── metrics-charts.md       # CloudWatch 圖表產生模板
    ├── report-template.md      # 報告模板（定期掃描 + 事件）
    └── analysis-principles.md  # 分析判讀原則與陷阱
```

## 前置需求

- 已設定 SSO 或 IAM profile 的 AWS CLI
- CloudWatch Logs、Athena（ALB logs 用）、CloudWatch Metrics 的存取權限
- Claude Code 的 Bash 工具存取權限

## License

MIT
