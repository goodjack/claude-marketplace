# AGENTS.md

以台灣正體中文與台灣用語回應與撰寫。

## 修訂流程

- 一律開 feature branch（`feat/<主題>`、`fix/<主題>`、`docs/<主題>`）走 PR，不直接 commit 到 main。
- Merge 用 squash：PR 標題用 Conventional Commits（scope 用 plugin 名，例 `feat(writing-style): ...`），squash 後即 main 上的 commit 訊息。
- 修訂紀錄記在 commit message，plugin 內不放 changelog 檔。
- SKILL.md 本文超過 500 行時拆到 references/。
- 本 repo 公開：所有內容（commit、PR、檔案、註解）不得出現任何公司或組織的內部識別。

## 版號管理

發版流程見 README.md 的「版號管理」段落。補充幾個原則：

- 使用者端的更新偵測靠 `plugin.json` 的 `version` 變更；該升版沒升，使用者就收不到更新。
- 升版前先判斷這次變更是否影響使用者功能：
  - skill 規則增修、新增指令、hook 行為改變 → 要升版。semver 判準：向後相容的新增＝minor、不影響語意的修正＝patch、破壞性變更（改指令名稱、移除規則、hook 行為改變）＝major。
  - 純文件更新（README、AGENTS.md）或內部維護 → 不升版，避免使用者白白更新。
- 發版建 tag 一律走 `claude plugin tag` 流程，不要手動下 `git tag`：內建流程有驗證（working tree 乾淨、版號一致、tag 不重複），手動 tag 沒有這層保障。
- `claude plugin tag` 不加 `--push` 時只會建立本地 tag。要推送 tag 到遠端，需明確加上 `--push`，或另外執行 `git push origin --tags`。
- `marketplace.json` 的 plugin entry 不放 `version`：官方警告雙重宣告時 `plugin.json` 會無警告優先，另一邊必然過時（見 [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)）。plugin 的 description 在 `plugin.json` 與 `marketplace.json` 兩處隨功能增減同步更新。
