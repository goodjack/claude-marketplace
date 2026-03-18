---
name: reviewing-pull-request
argument-hint: [PR 編號]
version: 0.1.0
description: >-
  當使用者想對 GitHub Pull Request 進行 code review 時使用。
  提供行級 review comments，含嚴重度 badge 與 merge-result 分析。
  觸發條件：任何提及審查、檢視、看 PR 的請求——
  中文（審查/看一下/幫我看/CR）或英文（review/check/code review），
  搭配 PR 識別（#123、PR 456、pr789、GitHub PR URL），
  或在 PR 語境下的泛用請求。
  不確定是否該觸發時，傾向觸發。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - LSP
  - Bash(git *)
  - Bash(gh *)
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# Pull Request Code Review

使用 gh CLI 和 Git 進行完整審查。Review 基於 merge result（目標 branch + PR 變更）。

## 基本原則

- 使用台灣正體中文回應
- 使用 TaskCreate、TaskUpdate、TaskList 工具管理審查進度
- 只專注於問題、改進建議和風險，不提及優點或正面評價

## 審查任務

使用 TaskCreate 建立審查任務（每個階段一個）：
1. 「準備環境」/ activeForm: 「準備審查環境中」
2. 「分析 PR 並切換至 merge result」/ activeForm: 「分析 PR 中」
3. 「讀取與分析修改檔案」/ activeForm: 「讀取與分析程式碼中」
4. 「發佈 review comments」/ activeForm: 「發佈 review comments 中」
5. 「完成審查」/ activeForm: 「完成審查中」
6. 「返回原始分支」/ activeForm: 「返回原始分支中」

## 詳細步驟

### 階段 0: 確認 PR 編號

PR 編號： $ARGUMENTS

若未提供 PR 編號，執行 `gh pr list` 顯示開啟中的 PR 列表，讓使用者選擇。

---

### 階段 1: 準備環境

```bash
git fetch
git status
git branch --show-current
```

若有未提交的變更，執行 `git stash`。

記錄當前分支名稱。

---

### 階段 2: 分析 PR 並切換至 merge result

> **WHY merge result?** 在 merge result 上 review 能揭示整合問題（衝突、不相容的變更），僅在 PR branch 上 review 會漏掉這些。

取得 PR 資訊：

```bash
gh pr view <number> --json baseRefName,baseRefOid,headRefName,headRefOid,mergeable
```

記錄以下欄位：
- `headRefOid`（階段 4 作為 `commit_id`）
- `baseRefName`
- `mergeable`

> **WHY 記錄 headRefOid?** GitHub API 需要 PR head 的 commit SHA 作為 `commit_id` 來錨定 review comments。用 `baseRefOid` 會導致 HTTP 422。

若 `mergeable` 為 `null`：等待 5 秒後重新執行，仍為 `null` 則視為 `false`。

**`mergeable` 為 `true`：**

```bash
# 使用 Detached HEAD，避免建立本地分支導致污染與撞名
git fetch origin pull/<number>/merge
git checkout --detach FETCH_HEAD
```

**`mergeable` 為 `false`：**

```bash
gh pr checkout <number>

# 發佈警告
gh pr review <number> --comment -b "$(cat <<'EOF'
⚠️ 此 PR 有 merge conflict，review 基於 PR branch。
EOF
)"
```

查看變更差異：

```bash
git diff origin/<baseRefName>...HEAD
```

---

### 階段 3: 讀取與分析修改檔案

使用 Read 工具讀取所有修改檔案，並行調用一次讀取。

盡可能使用工具獲取型別資訊、引用關係和函數簽名。

若專案有 AGENTS.md 或 CLAUDE.md，先讀取並提取專案特有規範，作為審查依據。

重點關注：
- **程式碼正確性**：如函數參數是否完整、型別標註是否正確、有無型別轉換風險
- **遵循專案規範**：如是否符合專案架構模式、一致性、風格、命名慣例（類別/函數/變數）
- **效能影響**：如是否有效能問題或可優化之處
- **測試涵蓋率**：如是否有對應的測試案例
- **安全性考量**：如是否有安全漏洞或風險

準備具體的改進建議。分析完成後如有疑問，使用 AskUserQuestion 工具。

---

### 階段 4: 發佈 Review Comments

> **WHY 行號取自 PR head 而非 merge result?** 雖然你在 merge result 分支上工作，但 GitHub 期望的行號來自 PR head（`origin/<headRefName>`）。這個不匹配是發佈 line comment 時 422 錯誤的最主要原因。

使用 git grep 在 PR head 搜尋程式碼行以取得準確行號：

```bash
git grep -nF -C 3 "exact code line" origin/<headRefName> -- path/to/file
```

處理多處匹配時：增加上下文行數、使用更精確的搜尋字串、使用完整的函數簽名。

若 git grep 找不到，使用 GitHub API patch：

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/files | jq -r '.[N].patch'
```

行號解析邏輯：
- `@@` 標頭格式：`@@ -老檔案 +新檔案 @@`
- `+行號` 是來源 branch 的實際行號
- `+` 前綴的行：行號 +1
- 空格前綴的行：行號 +1
- `-` 前綴的行：不增加行號

發佈批次 review：

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/reviews --input - <<'EOF'
{
  "event": "COMMENT",
  "commit_id": "階段 2 記錄的 headRefOid",
  "body": "共發現 N 個回饋：\n\n**嚴重問題** (X)\n- EMOJI 標題1\n\n**需要改進** (Y)\n- EMOJI 標題2",
  "comments": [
    {
      "path": "file.py",
      "line": 10,
      "side": "RIGHT",
      "body": "![等級](BADGE_URL)\nEMOJI **標題**\n\n說明\n\n建議"
    }
  ]
}
EOF
```

Badge URL 依三種等級使用下面三個 URL
- 嚴重問題 MUST → https://img.shields.io/badge/嚴重問題%20MUST-red?style=for-the-badge
- 需要改進 SHOULD → https://img.shields.io/badge/需要改進%20SHOULD-orange?style=for-the-badge
- 建議優化 MAY → https://img.shields.io/badge/建議優化%20MAY-blue?style=for-the-badge

關鍵技術細節：
- `commit_id` 使用階段 2 的 `headRefOid`（不是 `baseRefOid`）
- HEREDOC 使用單引號 `'EOF'` 形式
- 內容不要跳脫（不要用 `\"` 或 `` \` ``），以使特殊字元在 GitHub 正確顯示
- Line comments 只能在 diff 範圍內，否則 HTTP 422 錯誤

僅在 line comment 無法表達時，用獨立的 `gh pr review --comment` 發佈，不要併入批次 review 的 `body` 欄位：

```bash
gh pr review <NUMBER> --comment -b "$(cat <<'EOF'
審查內容
EOF
)"
```

---

### 階段 5: 完成審查

提供審查摘要：
- 總共發佈的 comments 數量
- 按嚴重度分類統計

---

### 階段 6: 返回原始分支

```bash
git checkout <階段 1 記錄的原始分支>
```

若階段 1 有執行 stash：

```bash
git stash pop
```

---

## 驗證原則

- **查證而非猜測**：能查證的必須查證
  - 使用 Grep 查找定義
  - 使用 Read 閱讀相關實作
  - 必要時使用 podman 或其他工具測試
- **量化而非模糊**：提供具體數字、影響範圍、問題發生條件，避免「需要確認」等模糊表述
- **誠實標示**：明確區分三種類型的意見
  - 查證事實：已驗證的問題
  - 主觀建議：基於經驗的建議
  - 無法驗證：需要進一步確認的問題
- **修正前確認**：任何修正或刪除操作（如 comment、code、config）前必須先詢問使用者確認
