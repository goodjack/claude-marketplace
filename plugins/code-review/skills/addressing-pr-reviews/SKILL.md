---
name: addressing-pr-reviews
argument-hint: [PR 編號]
version: 0.1.0
description: >-
  處理 GitHub PR review 留言的完整回覆工作流：列出未解決/未回覆的 review threads、
  逐則查證留言宣稱是否屬實、分類決定採納或反駁、先回覆預計做法、修正 push 後附
  commit 回覆並 resolve conversation。當使用者要求處理/回覆/消化 PR review 留言、
  確認 review 留言是否合理、resolve conversation、修正 review 指出的問題、
  回 reviewer 或 Copilot/AI reviewer 留言時使用——
  即使只說「處理一下 PR 上的 review」也應觸發。
  與 reviewing-pull-request 的區別：本 skill 處理「收到的」review 留言，
  reviewing-pull-request 是「發出」review。
  不確定是否該觸發時，傾向觸發。
allowed-tools:
  - Read
  - Edit
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

# 回覆 PR Review 工作流

處理一個 GitHub PR 上所有未解決（unresolved）review threads 的標準流程：
盤點 → 查證 → 分類 → 初步回覆 → 修正 push → 完成回覆 + resolve → 收尾回報。

前提：`gh` CLI 已登入且對目標 repo 有寫入權限。
所有 API 指令模板見 [references/github-api.md](references/github-api.md)。

## 進度追蹤

使用 TaskCreate 為每個 Step 建立任務，執行時以 TaskUpdate 更新狀態（in_progress → completed）。
任務清單：
1. 「確認 PR」
2. 「盤點 threads」
3. 「查證宣稱」
4. 「分類」
5. 「初步回覆」
6. 「修正 push」
7. 「完成回覆 + resolve」
8. 「收尾回報」

## Step 0：確認 PR 編號

PR 編號： $ARGUMENTS

若未提供 PR 編號，執行 `gh pr list` 顯示開啟中的 PR 列表，讓使用者選擇。

## Step 1：盤點未解決 threads

用 GraphQL 撈出全部 review threads（REST 看不到 isResolved）。
對每個 thread 記下：`threadId`（PRRT_ 開頭，後續回覆與 resolve 都要用）、path/line、
isOutdated、留言全文、作者。

判定規則：
- `isResolved == false` → 列入待處理
- thread 最後一則留言作者不是 PR author（也不是自己）→ 視為「未回覆」
- 已回覆但未 resolve → 仍列入，只差 resolve 步驟

## Step 2：逐則查證（最重要的一步）

AI reviewer（Copilot、CodeRabbit 等）會幻覺出不存在的程式碼或慣例；人類 reviewer 也可能
記錯現況。**任何留言的事實宣稱，先查證再決定**，查證成本通常只是幾行 grep：

| 宣稱類型 | 查證方法 |
| --- | --- |
| 「某處程式碼是 X 寫法」 | Read 該檔案實際確認，幻覺常出現在這裡 |
| 「與慣例不一致」 | grep 統計兩種寫法在 codebase 的分布數量，用數字定論 |
| 「建議改用 Y 工具/fixture」 | 確認 Y 真的存在且可用，不存在則建議不可落地 |
| 「測試應該如何如何」 | 查同類問題的既有先例（codebase 怎麼處理、有無 TODO 慣例） |

查證會直接決定分類，且查到的證據（file:line、統計數字）就是回覆的素材。

## Step 3：分類

| 分類 | 條件 | 後續動作 |
| --- | --- | --- |
| 採納 | 宣稱屬實且建議可落地 | 修正 → 回覆附 commit |
| 部分採納 | 問題真實但建議不可落地或過度 | 用替代做法處理 → 回覆說明差異 |
| 反駁 | 前提錯誤或與現況不符 | 回覆附證據，不修正 |
| 確認回覆 | 提醒類（MAY/nit），不需改 code | 回覆說明定位或決策 |

resolve 與否不在此決定，統一在 Step 6 詢問使用者。

## Step 4：初步回覆（修正前）

對每個待處理 thread 先回覆，讓 reviewer 及早知道處理方向：
- 採納/部分採納 → 預計做法（一兩句）
- 反駁 → 不接受的理由 + 證據（file:line、統計數字）
- 確認回覆 → 直接給完整回覆

例外：若修正幅度小且同一個 session 內就會完成 push，初步與完成回覆可合併成一則
（做法 + commit 一起講），避免同 thread 短時間連發兩則洗版。

## Step 5：修正、驗證、push

- 依專案規範修正（品質檢查 + 最小相關測試），確認測試結果再 commit
- Commit 訊息遵循該 repo 慣例；review 回饋來源寫進 body
- 不同性質的修正拆開 commit（如程式碼修正與文件規範修正分開）
- Push 後記下 short SHA，回覆要引用

## Step 6：完成回覆 + resolve

回覆內容：已修正的附 commit short SHA；反駁的若 Step 4 已回覆完整理由則不重複。

Resolve 不要自行決定——留言帳號可能是人類同事用 AI review 工具發的，無法從帳號判斷
對方會不會回來看回覆。整理好每個 thread 的建議後詢問使用者，選項至少包含：

- 全部 resolve
- 全部不 resolve（留給 reviewer 確認）
- 依建議選擇性 resolve（列出逐 thread 建議清單讓使用者挑）

逐 thread 建議的參考依據（僅是給使用者的建議，不是決策）：
- 採納並已修正、確認回覆（提醒類）→ 傾向 resolve（留著只是噪音）
- 反駁、或希望 reviewer 回頭確認的 → 傾向留著（有爭議的 thread 自己關掉形同迴避討論）

## Step 7：收尾回報

回報給使用者，格式：

```
| Thread (path:line) | 分類 | 動作 | resolve |
| ... | 採納 | 修正 + 回覆 (sha) | ✅ |

[PR #N 連結](https://github.com/owner/repo/pull/N)
```

未 resolve 的 thread 註明原因（使用者決定留給 reviewer 回應等）。結尾必附 PR 頁面超連結。

## 主動詢問使用者（跨環節原則）

查證能解決「程式碼現況是什麼」，但解決不了「為什麼這樣設計、未來怎麼規劃」。任何環節
有建議、疑慮或不確定，主動詢問使用者，不要自行推測補完。用所在環境提供的結構化提問
機制（沒有就直接在對話中問）；非互動環境採保守預設，並在收尾回報標註待確認項。

常見該問的時機：
- 業務背景與定位：PR body 與留言只是當下快照，功能的長期定位、未來規劃、團隊默契只有
  使用者知道；回覆內容涉及這類描述時先確認，不要從 PR 描述推測
- 分類搖擺：查證後仍在採納與反駁之間拿不定 → 帶著證據與初步傾向問
- resolve 與否：整理逐 thread 建議後讓使用者決定（見 Step 6），不要逕自按下
- 已發出的回覆發現有誤：edit 既有留言（版面乾淨但不發通知）或新 reply 更正（保留決策
  時序、會通知讀者）各有取捨 → 給使用者選，不要逕自決定

## 回覆撰寫原則

- 語言跟隨 PR 既有留言的語言
- 證據優先：引用 file:line 與統計數字，不空口主張
- 反駁對事不對人：「查證後與現況不符」+ 證據，不評論 reviewer
- 一則回覆講完一件事，不在單一回覆塞多個主題
- 每則回覆固定以署名作結（讓 reviewer 分辨回覆出自哪個模型）。模型名稱用行銷名稱
  而非 model id（如 `Claude Opus 4.6`，非 `claude-opus-4-6`），任何廠牌模型同理；
  無法確定時填 `unknown model`：

  ```
  \n\n<sub>🤖 Replied by {模型名稱}</sub>
  ```
