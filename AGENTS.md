# AGENTS.md

以台灣正體中文與台灣用語回應與撰寫。

## 修訂流程

- 一律開 feature branch（`feat/<主題>`、`fix/<主題>`、`docs/<主題>`）走 PR，不直接 commit 到 main。
- Merge 用 merge commit；commit 訊息用 Conventional Commits（scope 用 plugin 名，例 `feat(writing-style): ...`）。
- 修訂紀錄記在 commit message，plugin 內不放 changelog 檔。
- 本 repo 公開：所有內容（commit、PR、檔案、註解）不得出現任何公司或組織的內部識別。

## Skill 撰寫規範

部分 skill 也會給 Claude Code 以外的 agent 讀，以下寫法以跨工具都成立為準。

- **觸發資訊**：description 前 200 字元寫用途與觸發詞。`when_to_use` 是 Claude Code 專屬欄位，其他 agent 只讀 `name` 與 `description`，觸發資訊不能只放在 `when_to_use`。
- **長度**：SKILL.md 本文以少於 500 行、5k token 為目標（Anthropic 的撰寫建議，不是硬上限），超過就把只在特定情況用得到的內容搬到 references/。Claude Code 壓縮對話後每個 skill 只重貼本文前段，核心流程與陷阱放前面。
- **references**：超過 100 行的參考檔在檔頭加目錄；SKILL.md 直接指向每一份參考檔，不讓某份參考檔只能透過另一份參考檔找到。
- **不寫死模型與時點**：不寫具體模型名與版本，用相對層級描述（主對話模型、最低階可用模型這類）；落款範例寫「行銷名稱而非 model id」。日期、量測數字與事件經過不放執行指引，放 references 的設計紀錄或 commit message。
- **frontmatter**：以 Agent Skills 開放規格的六個欄位為主（`name`、`description`、`license`、`compatibility`、`metadata`、`allowed-tools`）；加 Claude Code 專屬欄位時，接受其他 agent 會忽略它。

## 版號管理

發版流程見 README.md 的「版號管理」段落。補充幾個原則：

- 使用者端的更新偵測靠 `plugin.json` 的 `version` 變更；該升版沒升，使用者就收不到更新。
- 升版前先判斷這次變更是否影響使用者功能：
  - skill 規則增修、新增指令、hook 行為改變 → 要升版。semver 判準：向後相容的新增＝minor、不影響語意的修正＝patch、破壞性變更（改指令名稱、移除規則、hook 行為改變）＝major。
  - 純文件更新（README、AGENTS.md）或內部維護 → 不升版，避免使用者白白更新。
- 發版建 tag 一律走 `claude plugin tag` 流程，不要手動下 `git tag`：內建流程有驗證（working tree 乾淨、版號一致、tag 不重複），手動 tag 沒有這層保障。
- `claude plugin tag` 不加 `--push` 時只會建立本地 tag。要推送 tag 到遠端，需明確加上 `--push`，或另外執行 `git push origin --tags`。
- 執行前先確認站在 main 且與遠端同步，並用 `--dry-run` 核對 plugin 名與版號：tag 建在當前 HEAD，站錯 branch 會把未 merge 的版號標到錯的 commit。
- 指令用 path 參數指定 plugin（形式見 README「版號管理」），不要寫成 `cd <plugin 目錄> && claude plugin tag`：複合指令裡的 `cd` 會觸發權限詢問而中斷。
- 站在 main 且 `--dry-run` 核對無誤後，建立與推送 tag 由 AI 直接執行，不需逐次請示。
- `marketplace.json` 的 plugin entry 不放 `version`：官方警告雙重宣告時 `plugin.json` 會無警告優先，另一邊必然過時（見 [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)）。plugin 的 description 在 `plugin.json` 與 `marketplace.json` 兩處隨功能增減同步更新。
