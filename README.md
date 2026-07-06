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

統一程式碼審查工具，支援 PR review、local review、CI 自動化審查。

包含以下 skills：
- **review** — 統一程式碼審查，支援 PR review（行級 GitHub comments）和 local review（終端機輸出），CI 環境自動偵測
- **addressing-pr-reviews** — 處理收到的 PR review 留言：盤點未解決 threads、查證宣稱、分類採納/反駁、回覆 reviewer、修正 push 並 resolve

### aws-investigate

AWS 線上環境調查工具——error 分析、效能劣化追查、基礎設施異常診斷。

包含以下 skills：
- **aws-investigate** — 調查 AWS 線上環境的 error、效能劣化、基礎設施異常，支援定期掃描（彙總+篩選+報告）與特定問題調查（trace 追蹤+root cause 分析）

## 安裝特定 Plugin

```bash
/plugin install <plugin-name>@goodjack-claude-marketplace
```
