#!/usr/bin/env bash
# PostToolUse hook wrapper：對 Edit/Write 的目標 .md 檔跑文件形狀檢查
#（同步層長度、符號串接、破折號與分號）。
# 發現問題時以 additionalContext 回饋給模型（advisory，不阻擋）——
# 這三項是「模型讀了規則也守不住」的形狀問題，由模型自行判斷是否改寫。
set -uo pipefail

payload="$(cat)"
f="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$payload" 2>/dev/null)"
[[ -z "$f" || ! -f "$f" ]] && exit 0
[[ "$f" == *.md ]] || exit 0

# 規則檔與範例／詞表類檔案本身就常見長段落、破折號、對照符號——跳過避免必然誤報
# （CLI 版不排除，手動跑要能檢查任何檔）。references 只排除 skill 自己的參考檔
#（*/skills/*/references/*），一般專案的 references 目錄要照掃。
case "$f" in
  */CLAUDE.md|*/AGENTS.md|*/backlog.md|*/skills/*/references/*) exit 0 ;;
esac

result="$("$(dirname "$0")/check-doc-shape.sh" "$f" 2>/dev/null)" || true

if grep -q "⚠️" <<<"$result"; then
  ctx="文件形狀檢查（${f}）發現問題。
${result}"
  jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
fi
exit 0
