#!/usr/bin/env bash
# 文件形狀檢查：掃描 .md 檔案，抓「模型讀了規則也守不住」的三類文件形狀問題。
# 用法：check-doc-shape.sh <檔案...>
# 定位：警示工具（人工判斷），可掛 PostToolUse hook 當確定性防線。
# 只檢查 .md 檔；其他副檔名（或不存在的路徑）直接跳過，不輸出任何內容。
#
# 三項檢查：
#   1. 同步層長度——去掉 YAML frontmatter 與第一行 H1 後，從第一個非空行到
#      第一個 "## " 之前的文字，超過門檻就提醒搬去小節。
#   2. 符號串接——正文（排除 code fence／表格／frontmatter／inline code）用
#      → ＋ ＝ ／ & 串接語意關係，而非寫成完整句子。命中摘錄取觸發符號前後
#      各 15 字，不是行首 40 字，確保摘錄看得到觸發符號本身。
#   3. 破折號與分號——正文（同上，另排除 inline code）用 —— ── — ； ; 斷句過量。
#
# 檢查二、三的命中例子各最多列 5 個，超過的以「…另 N 處」收尾；總數（處數／
# 行數）不受此上限影響，照樣完整回報。檢查一本來就只有一則，不設上限。
#
# 字元計數採「用 wc -m 的算法」（多位元組字元算一個），但改在 perl 內用
# UTF-8 decode 後的 length() 實作，不直接 shell 出去跑 wc -m：實測 wc -m
# 在 LC_ALL=C 環境會退化成 byte count（把中文算成 3），跑 hook 的殼層不保證
# 一定是 UTF-8 locale，perl 內部 decode 才不受呼叫端 locale 影響。
set -uo pipefail

SYNC_LAYER_LIMIT="${WRITING_STYLE_SYNC_LAYER_LIMIT:-400}"

found=0
checked_any=0

for f in "$@"; do
  [[ "$f" == *.md ]] || continue
  [[ -f "$f" ]] || continue
  checked_any=1

  result="$(SYNC_LAYER_LIMIT="$SYNC_LAYER_LIMIT" perl - "$f" <<'PERL_SCRIPT'
use strict;
use warnings;
use utf8;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $file = shift @ARGV;
exit 0 unless defined $file;

open(my $fh, '<:encoding(UTF-8)', $file) or exit 0;
my @L = ('');  # 1-indexed，$L[0] 不使用
while (my $line = <$fh>) {
  chomp $line;
  push @L, $line;
}
close $fh;
my $n = $#L;

my $LIMIT = $ENV{SYNC_LAYER_LIMIT};
$LIMIT = 400 unless defined $LIMIT && $LIMIT =~ /^\d+$/;

# 反引號改用 chr(96) 組字串：字面反引號放進這支 bash heredoc 裡，
# 奇數個會讓外層 bash 的引號配對解析失敗（實測重現，不是理論疑慮）。
my $BT = chr(96);

# ---------- 找 frontmatter／H1／第一個 "## " ----------
my $fm_end = 0;
if ($n >= 1 && $L[1] eq '---') {
  for (my $i = 2; $i <= $n; $i++) {
    if ($L[$i] eq '---') { $fm_end = $i; last; }
  }
}

my $body_start = $fm_end + 1;
my $j = $body_start;
while ($j <= $n && $L[$j] =~ /^\s*$/) { $j++; }
my $h1_line = 0;
if ($j <= $n && $L[$j] =~ /^# /) { $h1_line = $j; }

my $first_h2 = 0;
for (my $i = $body_start; $i <= $n; $i++) {
  if ($L[$i] =~ /^## /) { $first_h2 = $i; last; }
}

# 同步層起點：H1 之後的第一個非空行；沒有 H1 就是 frontmatter 後第一個非空行
my $scan_from = $h1_line ? $h1_line + 1 : $body_start;
my $sync_start = $scan_from;
while ($sync_start <= $n && $L[$sync_start] =~ /^\s*$/) { $sync_start++; }

my $sync_end = $first_h2 ? $first_h2 - 1 : $n;

my $sync_text = '';
if ($sync_start <= $sync_end) {
  for (my $i = $sync_start; $i <= $sync_end; $i++) {
    my $t = $L[$i];
    $t =~ s/^\s+//;
    $t =~ s/\s+$//;
    $sync_text .= $t;
  }
}
my $sync_len = length($sync_text);

my @issues;

if ($first_h2 == 0) {
  if ($sync_len > $LIMIT) {
    push @issues, "同步層 ${sync_len} 字元，超過 ${LIMIT}：沒有小節分隔，整份都是同步層。";
  }
} else {
  if ($sync_len > $LIMIT) {
    push @issues, "同步層（第一個 ## 之前）${sync_len} 字元，超過 ${LIMIT}：同步層只放結論、已決定的事、要讀者做的事、哪裡可以停；其餘後置到 ## 小節，不是刪掉。";
  }
}

# ---------- 正文行判定：排除 frontmatter／code fence／表格 ----------
my @is_body = (0) x ($n + 1);
my $in_fence = 0;
for (my $i = 1; $i <= $n; $i++) {
  if ($fm_end && $i <= $fm_end) { $is_body[$i] = 0; next; }
  if ($L[$i] =~ /^\Q$BT$BT$BT\E/) {
    $in_fence = !$in_fence;
    $is_body[$i] = 0;
    next;
  }
  if ($in_fence) { $is_body[$i] = 0; next; }
  if ($L[$i] =~ /^\s*\|/) { $is_body[$i] = 0; next; }
  $is_body[$i] = 1;
}

# ---------- 檢查二：符號串接 ----------
# → ＋ ＝ 任意出現；／ 與 & 只抓兩側都是中文字或英數（不抓路徑／URL，
# 因為路徑用半形 /，這裡只比對全形 ／）；比照檢查三，另去除 inline code。
my $sym_re = qr/→|＋|＝|[\p{Han}A-Za-z0-9]／[\p{Han}A-Za-z0-9]|\p{Han}&\p{Han}/;
my @sym_hits;
for (my $i = 1; $i <= $n; $i++) {
  next unless $is_body[$i];
  my $line = $L[$i];
  $line =~ s/\Q$BT\E[^$BT]*\Q$BT\E//g;  # 去除 inline code
  if ($line =~ /$sym_re/) {
    my $start = $-[0];
    my $end = $+[0];
    my $ctx_start = $start - 15;
    my $lead = "";
    if ($ctx_start < 0) { $ctx_start = 0; } else { $lead = "…"; }
    my $ctx_end = $end + 15;
    my $trail = "";
    if ($ctx_end >= length($line)) { $ctx_end = length($line); } else { $trail = "…"; }
    my $excerpt = substr($line, $ctx_start, $ctx_end - $ctx_start);
    push @sym_hits, "  第 ${i} 行：${lead}${excerpt}${trail}";
  }
}
if (@sym_hits) {
  my $total = scalar(@sym_hits);
  my @shown = @sym_hits;
  my $extra = 0;
  if ($total > 5) {
    @shown = @sym_hits[0..4];
    $extra = $total - 5;
  }
  my $msg = "正文用符號串接語意關係（→ ＋ ＝ ／ &），改寫成完整句子或條列。\n" . join("\n", @shown);
  $msg .= "\n  …另 ${extra} 處" if $extra > 0;
  push @issues, $msg;
}

# ---------- 檢查三：破折號與分號（正文行，另去除 inline code）----------
my $dash_count = 0;
my $semi_count = 0;
my @hit_lines;
for (my $i = 1; $i <= $n; $i++) {
  next unless $is_body[$i];
  my $line = $L[$i];
  $line =~ s/\Q$BT\E[^$BT]*\Q$BT\E//g;  # 去除 inline code
  my $hit_here = 0;
  while ($line =~ /[—─]+/g) { $dash_count++; $hit_here = 1; }
  while ($line =~ /[;；]/g) { $semi_count++; $hit_here = 1; }
  push @hit_lines, $i if $hit_here;
}
if ($dash_count > 0 || $semi_count > 0) {
  my $total_lines = scalar(@hit_lines);
  my @shown = @hit_lines;
  my $extra = 0;
  if ($total_lines > 5) {
    @shown = @hit_lines[0..4];
    $extra = $total_lines - 5;
  }
  my $lines_str = join('、', map { "第${_}行" } @shown);
  $lines_str .= "、…另 ${extra} 處" if $extra > 0;
  push @issues, "破折號 ${dash_count} 處、分號 ${semi_count} 處：一句一事，改用句號斷開或改條列。\n  出現於：${lines_str}";
}

if (@issues) {
  print join("\n\n", map { "⚠️  $_" } @issues), "\n";
}
PERL_SCRIPT
)"

  if [[ -n "$result" ]]; then
    found=1
    echo "檔案：$f"
    echo "$result"
    echo
  fi
done

if [[ "$checked_any" -eq 1 && "$found" -eq 0 ]]; then
  echo "✅ 未發現文件形狀問題"
fi
exit "$found"
