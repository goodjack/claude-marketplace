#!/usr/bin/env bash
# 台灣用語檢查：掃描檔案或 stdin 中的中國用語，列出行號與建議替換。
# 用法：check-tw-terms.sh <檔案...>  或  echo "文字" | check-tw-terms.sh
# 定位：警示工具（人工判斷），可掛 PostToolUse/Stop hook 當確定性防線。
# 詞表來源：../skills/writing-style/references/taiwan-terms.md
# （此處為可機械比對的高頻子集；帶括號註記的條目無法 grep，全表以詞表檔為準）。
#
# 比對前先遮掉兩類文字，因為那是引用原文或名稱，不是行文用字：
#   - 引號內的文字：「…」『…』“…” 與半形雙引號
#   - 行內程式碼：單或雙反引號包起來的部分
# 引號與行內程式碼各自只在同一行內配對；跨行的引號不處理。code fence 區塊不遮。
# 條目可附第三欄「前綴例外」（用「、」分隔）：前面緊接這些詞時不算命中，
# 例如「會員代碼」「錯誤代碼」是台灣慣用的名稱，「程式代碼」仍會報。
set -uo pipefail

if ! command -v perl >/dev/null 2>&1; then
  echo "⚠️ 無法完成台灣用語檢查：找不到 perl"
  exit 2
fi

# 格式：禁用詞|建議[|前綴例外（用「、」分隔）]
TERMS=(
  "靜默|直接／背景／自動／不報錯"
  "閾值|門檻值"
  "文檔|文件"
  "代碼|程式碼|會員、類目、郵遞、狀態、錯誤、產品、國家、地區、科目、職務、行業"
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
  "頭像|大頭貼"
  "首屏|第一個畫面／最上方"
  "佔位符|預留位置／placeholder"
  "技術棧|tech stack"
  "運營|營運"
  "落地|實現／導入／上線"
  "抓手|（浮誇商業詞，改寫）"
  "賦能|（浮誇商業詞，改寫）"
  "痛點|（浮誇商業詞，改寫）"
)

input="$(cat "${@:-/dev/stdin}" 2>/dev/null)"
[[ -z "$input" ]] && exit 0

# 用 read 把 perl 程式讀進變數（不放進 $(...) 內的 heredoc），避開舊版 bash 3.2
# 解析 heredoc 時落單的括號與引號出錯；引號與反引號仍用 \x22、\x60 表示。
IFS= read -r -d '' PERL_SRC <<'PERL_SCRIPT' || true
use strict;
use warnings;
no warnings 'utf8';   # 非 UTF-8 的輸入不要在 stderr 噴警告
use utf8;
binmode(STDOUT, ':utf8');

# 遮罩：引號內文字與行內程式碼換成一個空格（避免兩側字元被接成詞）。
# 用單一 alternation 由左而右配對，巢狀引號（「…『…』…」）整段一起遮。
sub mask_line {
  my ($t) = @_;
  $t =~ s/「[^」]*」|『[^』]*』|“[^”]*”|\x22[^\x22]*\x22|\x60\x60.*?\x60\x60|\x60[^\x60]*\x60/ /g;
  return $t;
}

my @raw;
while (my $l = <STDIN>) { chomp $l; push @raw, $l; }
my @masked = map { mask_line($_) } @raw;

my $found = 0;
for my $entry (@ARGV) {
  my ($term, $suggestion, $prefixes) = split(/\|/, $entry, 3);
  my $re = quotemeta($term);
  if (defined $prefixes && length $prefixes) {
    my $alt = join('|', map { quotemeta } split(/、/, $prefixes));
    $re = "(?<!$alt)$re";
  }
  my @hits;
  for my $i (0 .. $#masked) {
    next unless $masked[$i] =~ /$re/;
    push @hits, sprintf('    %d:%s', $i + 1, $raw[$i]);
    last if @hits >= 3;
  }
  next unless @hits;
  $found = 1;
  print "⚠️  「${term}」→ 建議：${suggestion}\n";
  print "$_\n" for @hits;
}
print "✅ 未發現清單內的中國用語\n" unless $found;
exit $found;
PERL_SCRIPT

printf '%s\n' "$input" | perl -CSA -e "$PERL_SRC" -- "${TERMS[@]}"
exit $?
