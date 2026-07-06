---
name: review
argument-hint: [PR 編號]
description: >-
  統一程式碼審查工具，支援 PR review 和 local review。
  PR review：提供 PR# 時觸發，發佈行級 GitHub review comments。
  Local review：不提供 PR# 時觸發，審查本地未推送的變更並在終端機輸出。
  觸發條件：任何提及審查、檢視、看 PR 的請求——
  中文（審查/看一下/幫我看/CR）或英文（review/check/code review），
  搭配 PR 識別（#123、PR 456、pr789、GitHub PR URL），
  或在 PR 語境下的泛用請求。
  Local review 觸發：「review 本地改動」「看目前的修改」「review my branch」等。
  CI 環境自動偵測並切換為唯讀模式。
  不確定是否該觸發時，傾向觸發。
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - LSP
  - Bash(${CLAUDE_SKILL_DIR}/scripts/*)
  - Bash(git *)
  - Bash(gh *)
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
---

# Code Review

統一程式碼審查。依 `$ARGUMENTS` 自動判斷模式：有 PR 編號 → PR review；無 → local review。

使用正體中文台灣用語。只專注於問題、改進建議和風險，不提及優點或正面評價。

## 環境資訊

- 系統環境： !`${CLAUDE_SKILL_DIR}/scripts/detect-mode`
- gh 指令： !`command -v gh >/dev/null 2>&1 && echo "exists" || echo "not found"`
- 預設 Repo： !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "unknown"`
- Plugin 版本： !`jq -r '.version // "unknown"' "${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json" 2>/dev/null || echo "unknown"`

### CI 模式（系統環境為 `ci`）

- 不執行環境準備與還原（階段 1、6）
- **唯讀**：只發佈 review comments，絕不修改程式碼或推送 commits
- **自主判斷**：無法詢問使用者，需自行決定所有判斷
- 不使用 TaskCreate / TaskUpdate / AskUserQuestion

### 互動模式（系統環境為 `interactive`）

- 使用 TaskCreate 管理審查進度（每個階段一個任務）：
  1. 「準備環境」/ activeForm: 「準備審查環境中」
  2. 「取得變更差異」/ activeForm: 「分析中」
  3. 「讀取與分析修改檔案」/ activeForm: 「讀取與分析程式碼中」
  4. 「發佈審查結果」/ activeForm: 「發佈審查結果中」
  5. 「完成審查」/ activeForm: 「完成審查中」
  6. 「還原環境」/ activeForm: 「還原環境中」
- 分析完成後如有疑問，使用 AskUserQuestion 工具
- 任何修正或刪除操作前必須先詢問使用者確認

## 詳細步驟

### 階段 0: 判斷 review 模式

$ARGUMENTS

- 有 PR 編號 → **PR review 模式**
- 無 PR 編號但使用者意圖為 PR review（如提及 PR、review PR）→ **PR review 模式**（從下方列表選擇）
- 無 PR 編號且未提及 PR → **Local review 模式**

若需選擇 PR（僅互動模式），從下面列表中選擇：

!`gh pr list 2>/dev/null`

---

### 階段 1: 準備環境（僅互動模式）

```bash
git fetch
git status
git branch --show-current
```

若有未提交的變更，執行 `git stash`。記錄當前分支名稱。

---

### 階段 2: 取得變更差異

#### PR review 模式

##### Auto-skip 檢查

```bash
gh pr view <number> --json state,isDraft
```

- `state` 非 `OPEN` → 跳過並通知
- `isDraft` 為 `true` → CI 模式：跳過並通知；互動模式：詢問是否繼續

##### Checkout merge result

> **WHY merge result?** 在 merge result 上 review 能揭示整合問題（衝突、不相容的變更），僅在 PR branch 上 review 會漏掉這些。

```bash
gh pr view <number> --json baseRefName,headRefName,headRefOid,mergeable
```

記錄 `headRefOid`、`baseRefName`、`mergeable`。

> **WHY headRefOid?** GitHub API 需要 PR head 的 commit SHA 作為 `commit_id` 來錨定 review comments。用 `baseRefOid` 會導致 HTTP 422。

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
```

記錄 merge conflict 狀態（警告併入階段 4 批次 review body 最前面）。

查看變更差異：

```bash
git diff origin/<baseRefName>...HEAD
```

#### Local review 模式

```bash
UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "origin/main")
git diff "origin/${UPSTREAM#origin/}...HEAD"
```

不需 checkout merge result，不需記錄 headRefOid。

---

### 階段 3: 讀取與分析修改檔案

使用 Read 工具讀取所有修改檔案，並行調用一次讀取。盡可能使用工具獲取型別資訊、引用關係和函數簽名。

#### 審查依據（優先順序）

1. REVIEW.md（若專案根目錄存在，最高優先級）
2. AGENTS.md / CLAUDE.md
3. 通用最佳實踐

#### 審查重點

- **程式碼正確性**：函數參數是否完整、型別標註是否正確、有無型別轉換風險
- **遵循專案規範**：是否符合專案架構模式、一致性、風格、命名慣例
- **效能影響**：是否有效能問題或可優化之處（如 N+1 query）
- **測試涵蓋率**：是否有對應的測試案例
- **安全性考量**：是否有安全漏洞或風險
- **向後相容性**：當 diff 涉及 API、DB schema、公開介面時，檢查是否有破壞性變更

必要時使用 `git blame` / `git log` 了解變更的歷史脈絡，判斷修改是否合理。

#### 嚴重度判斷

- 🔴 **MUST**（嚴重問題）：安全漏洞、正確性錯誤（資料遺失、邏輯錯誤）、穩定性問題、違反團隊明確規範
- 🟠 **SHOULD**（需要改進）：可維護性（重複邏輯、過深巢狀）、非關鍵路徑的穩健性、非關鍵效能問題（如 N+1 query）、業界最佳實踐
- 🔵 **MAY**（建議優化）：超出 linter 範圍的風格偏好、無明確優劣的替代方案。按價值排序，最多列出 5 個，超過在摘要標註「另有 N 個同類建議」
- 🟣 **PRE-EXISTING**（既有問題，附加標記）：用 `git blame` 確認問題程式碼在 diff 之外已存在後**附加**此標記——嚴重度仍依問題本身標為 MUST/SHOULD/MAY，PRE-EXISTING 只註記來源，與嚴重度並存、不取代（否則高嚴重度的既有問題會被遮蔽，例如既有的 MUST 級安全漏洞只剩紫色標記）。PR review 表示「非此 PR 引入」；local review 表示「既有問題，考慮一併修正」

決策樹：可能導致錯誤結果或安全風險？→ MUST。團隊有明確規範？→ MUST。6 個月後會讓人踩坑？→ SHOULD。只是「我覺得另一種寫法更好」？→ MAY。

#### 分析原則

- **查證而非猜測**：使用 Grep 查找定義、Read 閱讀相關實作、必要時使用工具測試
- **量化而非模糊**：提供具體數字、影響範圍、問題發生條件，避免「需要確認」等模糊表述
- **誠實標示**：明確區分三種類型——查證事實（已驗證的問題）、主觀建議（基於經驗）、無法驗證（需進一步確認）

---

### 階段 4: 發佈審查結果

#### PR review 模式

##### 行號定位

> **WHY 行號取自 PR head?** 雖然你在 merge result 分支上工作，但 GitHub 期望的行號來自 PR head（`origin/<headRefName>`）。這個不匹配是發佈 line comment 時 422 錯誤的最主要原因。

使用 git grep 在 PR head 搜尋程式碼行以取得準確行號：

```bash
git grep -nF -C 3 "exact code line" origin/<headRefName> -- path/to/file
```

處理多處匹配：增加上下文行數、使用更精確的搜尋字串、使用完整的函數簽名。

若 git grep 找不到，使用 GitHub API patch：

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/files | jq -r '.[N].patch'
```

行號解析邏輯：
- `@@` 標頭格式：`@@ -舊檔案 +新檔案 @@`
- `+行號` 是來源 branch 的實際行號
- `+` 前綴的行：行號 +1
- 空格前綴的行：行號 +1
- `-` 前綴的行：不增加行號

##### 發佈前防呆

發佈 inline comment 前，逐則驗證行號與引用程式碼相符，避免 comment 掛錯行：

1. 用 `gh api repos/{owner}/{repo}/pulls/{n}/files` 取得目標檔案的 patch
2. 從 patch 定位你要 comment 的行號，確認該行 ±1 行的內容與你引用的程式碼相符
3. 不相符 → 依上方「行號解析邏輯」重算行號，回到步驟 2 再驗證一次
4. 連續兩次不相符 → 放棄行級定位，改用 PR-level comment（`POST /pulls/{n}/reviews` 的 `comments[]` 不支援 `subject_type`，無法在批次 review 內做 file-level）：用下方「僅在 line comment 無法表達時」的獨立 `gh pr review --comment` 發佈，內文註明對應的檔案路徑、程式碼片段與大約位置

##### 發佈批次 review

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/reviews --input - <<'EOF'
{
  "event": "COMMENT",
  "commit_id": "階段 2 記錄的 headRefOid",
  "body": "（若有 merge conflict）⚠️ 此 PR 有 merge conflict，review 基於 PR branch。\n\n---\n\n共發現 N 個回饋（其中 Z 個為既有問題 PRE-EXISTING）：\n\n**嚴重問題** (X)\n- {主題emoji} 標題1\n\n**需要改進** (Y)\n- {主題emoji} 標題2（PRE-EXISTING）\n\n**建議優化** (W)\n- {主題emoji} 標題3\n\n<sub>🤖 Reviewed by {模型名稱} · code-review v{plugin 版本}</sub>",
  "comments": [
    {
      "path": "file.py",
      "line": 10,
      "side": "RIGHT",
      "body": "![等級](BADGE_URL)\n{主題emoji} **標題**\n\n說明\n\n建議"
    }
  ]
}
EOF
```

Badge URL：
- 🔴 MUST → `https://img.shields.io/badge/嚴重問題%20MUST-red?style=for-the-badge`
- 🟠 SHOULD → `https://img.shields.io/badge/需要改進%20SHOULD-orange?style=for-the-badge`
- 🔵 MAY → `https://img.shields.io/badge/建議優化%20MAY-blue?style=for-the-badge`
- 🟣 PRE-EXISTING → `https://img.shields.io/badge/既有問題%20PRE--EXISTING-purple?style=for-the-badge`

既有問題（PRE-EXISTING）是附加標記，不是嚴重度等級：該 comment 仍先放上述嚴重度 badge，再於其後接上既有問題 badge 並存，不取代嚴重度。

技術細節：
- `commit_id` 使用階段 2 記錄的 `headRefOid`（不是 `baseRefOid`）
- HEREDOC 使用單引號 `'EOF'` 形式，內容不要跳脫（不要用 `\"` 或 `` \` ``），以使特殊字元在 GitHub 正確顯示
- Line comments 只能在 diff 範圍內，否則 HTTP 422
- 模型名稱填入實際名稱（如 `Claude Opus 4.6`），無法確定填 `unknown model`；版本取自環境資訊
- 無 merge conflict 時省略警告和分隔線
- 無問題時 body 以「無發現嚴重問題」開頭

僅在 line comment 無法表達時，用獨立的 `gh pr review --comment` 發佈，不要併入批次 review 的 `body` 欄位：

```bash
gh pr review <NUMBER> --comment -b "$(cat <<'EOF'
審查內容
EOF
)"
```

#### Local review 模式

直接在終端機以 Markdown 格式輸出，不呼叫 GitHub API：

```
## 審查結果

共發現 N 個回饋（其中 W 個為既有問題 PRE-EXISTING）：

### 🔴 嚴重問題 (X)
1. **標題** — `file.py:10`
   說明 + 建議

### 🟠 需要改進 (Y)
1. **標題（PRE-EXISTING）** — `legacy.py:42`
   說明 + 建議

### 🔵 建議優化 (Z)
...

```

---

### 階段 5: 完成審查

**PR review 模式：** 批次 review body 已含摘要（見階段 4 範本）。在終端機也提供統計。

**Local review 模式：**

```
## 審查摘要
共 N 個回饋：X 個嚴重問題 / Y 個需要改進 / Z 個建議優化
```

無問題時以「無發現嚴重問題」開頭。

---

### 階段 6: 還原環境（僅互動模式 + PR review 模式）

```bash
git checkout <階段 1 記錄的原始分支>
```

若階段 1 有執行 stash：

```bash
git stash pop
```
