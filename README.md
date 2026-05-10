# goodjack-claude-marketplace

goodjack 的個人 Claude Code plugin marketplace。

## 安裝

```bash
/plugin marketplace add goodjack/claude-marketplace
```

或使用本地路徑：

```bash
/plugin marketplace add ./path/to/goodjack-claude-marketplace
```

## 可用 Plugins

### code-review

PR code review 工具，含互動式與 CI 自動化審查。

包含以下 skills：
- **reviewing-pull-request** — 互動式 PR code review，提供行級 review comments，含嚴重度 badge 與 merge-result 分析
- **reviewing-pull-request-ci** — CI/CD 環境專用的非互動式 PR review，適用於 GitHub Actions 自動化審查

### aws-investigate

AWS 線上環境調查工具——error 分析、效能劣化追查、基礎設施異常診斷。

包含以下 skills：
- **aws-investigate** — 調查 AWS 線上環境的 error、效能劣化、基礎設施異常，支援定期掃描（彙總+篩選+報告）與特定問題調查（trace 追蹤+root cause 分析）

## 安裝特定 Plugin

```bash
/plugin install <plugin-name>@goodjack-claude-marketplace
```
