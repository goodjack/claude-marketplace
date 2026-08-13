#!/usr/bin/env bash
# 台灣用語檢查：掃描檔案或 stdin 中的中國用語，列出行號與建議替換。
# 用法：check-tw-terms.sh <檔案...>  或  echo "文字" | check-tw-terms.sh
# 定位：警示工具（人工判斷），可掛 PostToolUse/Stop hook 當確定性防線。
# 詞表來源：../skills/writing-style/references/taiwan-terms.md
# （此處為可機械比對的高頻子集；帶括號註記的條目無法 grep，全表以詞表檔為準）。
set -uo pipefail

# 格式：禁用詞|建議
TERMS=(
  "靜默|直接／背景／自動／不報錯"
  "閾值|門檻值"
  "文檔|文件"
  "代碼|程式碼"
  "數據庫|資料庫"
  "日誌|Log／紀錄"
  "配置|設定／組態"
  "硬編碼|寫死"
  "組件|元件"
  "調用|呼叫"
  "嵌套|巢狀"
  "複用|共用／重複使用"
  "重用|共用／重複使用"
  "回退|降版／還原／回復到上一版"
  "刷新|重新整理／更新"
  "排查|除錯"
  "運行|運作"
  "接入|串接"
  "告警|警報"
  "根因|root cause／根本原因"
  "兜底|保底／fallback"
  "場景|情境"
  "信號|訊號"
  "觸達|送達／觸及"
  "聚合|彙總"
  "串行|序列"
  "並發|平行"
  "全量|整批"
  "增量|差異"
  "大概率|很可能／八成"
  "技術棧|tech stack"
  "運營|營運"
  "落地|實現／導入／上線"
  "抓手|（浮誇商業詞，改寫）"
  "賦能|（浮誇商業詞，改寫）"
  "痛點|（浮誇商業詞，改寫）"
)

input="$(cat "${@:-/dev/stdin}" 2>/dev/null)"
[[ -z "$input" ]] && exit 0

found=0
for entry in "${TERMS[@]}"; do
  term="${entry%%|*}"
  suggestion="${entry#*|}"
  hits=$(grep -n "$term" <<<"$input" | head -3)
  if [[ -n "$hits" ]]; then
    found=1
    echo "⚠️  「${term}」→ 建議：${suggestion}"
    sed 's/^/    /' <<<"$hits"
  fi
done

[[ "$found" -eq 0 ]] && echo "✅ 未發現清單內的中國用語"
exit "$found"
