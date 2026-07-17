# 貢獻與發佈慣例

本 repo 是 Claude Code plugin marketplace（`.claude-plugin/marketplace.json` 註冊 `plugins/<name>/` 各 plugin）。修訂任何內容照以下流程，不直接 commit 到 main。

## 修訂流程

1. 開 feature branch（`feat/<主題>`、`fix/<主題>` 或 `docs/<主題>`）。
2. 修改內容。SKILL.md 本文超過 500 行時拆到 references/。
3. Bump 該 plugin 的 `plugins/<name>/.claude-plugin/plugin.json` 的 `version`（semver）：
   - patch：錯字、措辭微調、不影響規則語意的修正。
   - minor：新增章節、規則、hook 等向後相容的功能。
   - major：會改變既有使用方式的破壞性變更（改指令名稱、移除規則、hook 行為改變）。
4. 開 PR，merge 用 merge commit（沿用本 repo 既有慣例，保留分支歷史）。
5. Merge 後在 main 打 annotated tag `<plugin>--v<version>`（例 `writing-style--v1.1.0`）並 push tag。

## 版號機制說明（依官方文件）

- 使用者端的更新偵測靠 `plugin.json` 的 `version` 變更；忘了 bump，使用者就收不到更新。
- `marketplace.json` 的 plugin entry 不放 `version`：官方警告雙重宣告時 `plugin.json` 會無警告優先，另一邊必然過時。
- git tag 供 plugin dependency 的 semver 範圍解析用，格式固定 `<plugin>--v<version>`。
- 參考：[Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)、[Plugin dependencies](https://code.claude.com/docs/en/plugin-dependencies)。

## 其他慣例

- Commit 訊息用 Conventional Commits，scope 用 plugin 名（例 `feat(writing-style): ...`）。
- 修訂紀錄記在 commit message，plugin 內不放 changelog 檔。
- 本 repo 公開：所有內容（commit、PR、檔案、註解）不得出現任何公司或組織的內部識別。
- Plugin 的 description（`plugin.json` 與 `marketplace.json`）要隨功能增減同步更新，兩處文字保持一致（version 除外，見上）。
