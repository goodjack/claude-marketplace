#!/usr/bin/env bash
# PostToolUse hook wrapper：對 Edit/Write 的目標檔案跑台灣用語檢查。
# 發現疑似中國用語時，以 additionalContext 回饋給模型（advisory，不阻擋）——
# 因為存在合法引用情境（詞表本體、文章中刻意舉例），由模型判斷是否修正。
set -uo pipefail

payload="$(cat)"
f="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$payload" 2>/dev/null)"
[[ -z "$f" || ! -f "$f" ]] && exit 0

# 詞表類檔案整份都是禁用詞對照，跳過避免必然誤報
# （CLAUDE.md 常見引用用語規則，整檔誤報率高，一併跳過）
case "$f" in
  */CLAUDE.md|*check-tw-terms*|*taiwan-terms*) exit 0 ;;
esac

result="$("$(dirname "$0")/check-tw-terms.sh" "$f" 2>/dev/null)" || true

if grep -q "⚠️" <<<"$result"; then
  ctx="台灣用語檢查（${f}）發現疑似中國用語。若是行文用字請立即修正；若是刻意引用（如詞表、舉例）則忽略此提醒。
${result}"
  jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
fi
exit 0
