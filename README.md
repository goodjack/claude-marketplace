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

### writing-style

文件與長回覆的寫作風格指南，依據 Google／Microsoft Style Guide、NN/g 掃描閱讀研究與教育部《重訂標點符號手冊》等公開來源整理。

包含以下 skills：
- **writing-style** — 產出任何給人讀的文件（報告、事件報告、調查分析、計畫書、設計文件）或長回覆時的寫作風格約束：預設掃讀文體（結論句在前、一行一事實條列）、讀者範圍、結構選擇（表格／條列／段落）、反壓縮條款（標點與詞彙層）、縮寫與代號首次定義、跨文件引用、中文行文慣例、AI 產出常見問題對照

包含以下 hooks：
- **台灣用語檢查**（PostToolUse，Edit/Write）— 寫檔後自動掃描目標檔案中的中國用語，發現時以提醒回饋給模型修正；advisory 不阻擋，詞表本體與刻意舉例等合法引用由模型自行判斷。詞表全表見 skill 的 `references/taiwan-terms.md`，hook 使用可機械比對的高頻子集

## 安裝特定 Plugin

```bash
/plugin install <plugin-name>@goodjack-claude-marketplace
```

## 版號管理

每個 plugin 的 `plugin.json` 都有 `version` 欄位，遵循 [Semantic Versioning](https://semver.org/lang/zh-TW/)。發版流程：

1. 更新該 plugin 的 `.claude-plugin/plugin.json` 的 `version`
2. Commit & merge 到 main
3. 在 repo 根目錄執行 `claude plugin tag --push plugins/<plugin 名>`

當 plugin 之間有相依關係時，可在 `dependencies` 中限制對方的版本範圍，避免上游破壞性更新影響下游。詳見 [Plugin Dependencies](https://docs.claude.com/zh-TW/docs/claude-code/plugin-dependencies)。
