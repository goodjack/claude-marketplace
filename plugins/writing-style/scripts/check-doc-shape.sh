#!/usr/bin/env bash
# 文件形狀檢查：掃描 .md 檔案，抓「模型讀了規則也守不住」的三類文件形狀問題。
# 用法：check-doc-shape.sh <檔案...>
# 定位：警示工具（人工判斷），可掛 PostToolUse hook 當確定性防線。
# 只檢查 .md 檔；其他副檔名（或不存在的路徑）直接跳過，不輸出任何內容。
#
# 三項檢查：
#   1. 同步層長度——去掉 YAML frontmatter 與第一行 H1 後，從第一個非空行到
#      第一個 "## " 之前的文字，超過門檻就提醒搬去小節。
#   2. 符號串接——正文（排除 code fence ``` 與 ~~~／表格／frontmatter／單雙
#      反引號 inline code／URL）用 → ＋ ＝ ／ & 串接語意關係，而非寫成完整
#      句子；「A → B → C」流程序列與數學式 notation 不算，訊息末尾會註明。
#      命中摘錄取觸發符號前後各 15 字，不是行首 40 字，確保看得到觸發符號。
#   3. 破折號與分號——正文（同上遮罩規則）用 —— ── — ； ; 斷句過量，訊息
#      是軟性提醒（確認是否過量／可能是合理的平列分句），不是強制改句號。
#
# 檢查二、三的命中例子各最多列 5 個，超過的以「…另 N 處」收尾；總數（處數／
# 行數）不受此上限影響，照樣完整回報。檢查一本來就只有一則，不設上限。
#
# 找不到 perl，或 perl 執行本身失敗（非語法內的「無命中」），一律印
# ⚠️ 訊息並讓 CLI 版 exit 2（不能悄悄回報成通過）；hook 版仍固定 exit 0
# 維持 advisory 不阻擋，失敗訊息照樣透過 additionalContext 讓模型看到。
#
# 字元計數採「用 wc -m 的算法」（多位元組字元算一個），但改在 perl 內用
# UTF-8 decode 後的 length() 實作，不直接 shell 出去跑 wc -m：實測 wc -m
# 在 LC_ALL=C 環境會退化成 byte count（把中文算成 3），跑 hook 的殼層不保證
# 一定是 UTF-8 locale，perl 內部 decode 才不受呼叫端 locale 影響。
set -uo pipefail

SYNC_LAYER_LIMIT="${WRITING_STYLE_SYNC_LAYER_LIMIT:-400}"

# 沒有 perl 就什麼都查不了：立刻回報失敗，不要讓後面的邏輯悄悄跑出「無命中」
# 的假結果（那會被讀成「通過」）。
if ! command -v perl >/dev/null 2>&1; then
  echo "⚠️ 無法完成文件形狀檢查：找不到 perl"
  exit 2
fi

found=0
checked_any=0
runtime_error=0

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
my $BT2 = $BT x 2;

# 檢查二、三共用的行文遮罩：先去雙反引號 code span（避免內部反引號被單反引號
# 規則誤判），再去單反引號 code span，最後移除 URL——但 URL 只吃到中日韓字元
# 或全形標點為止，避免 URL 後面直接接中文時把後面的中文（含觸發符號）也吃掉。
sub mask_line {
  my ($line) = @_;
  $line =~ s/\Q$BT2\E.*?\Q$BT2\E//g;
  $line =~ s/\Q$BT\E[^$BT]*\Q$BT\E//g;
  $line =~ s{https?://[^\s\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}（）「」『』、，。；：！？]+}{}g;
  return $line;
}

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
# fence 前置 0–3 個空白都算（CommonMark 慣例）；``` 只能被 ``` 關閉、
# ~~~ 只能被 ~~~ 關閉，不同字元不互相配對、不會誤關。
my @is_body = (0) x ($n + 1);
my $in_fence = 0;
my $fence_type = '';
for (my $i = 1; $i <= $n; $i++) {
  if ($fm_end && $i <= $fm_end) { $is_body[$i] = 0; next; }
  if (!$in_fence) {
    if ($L[$i] =~ /^[ ]{0,3}${BT}{3,}/) {
      $in_fence = 1; $fence_type = 'bt';
      $is_body[$i] = 0;
      next;
    }
    if ($L[$i] =~ /^[ ]{0,3}~{3,}/) {
      $in_fence = 1; $fence_type = 'tilde';
      $is_body[$i] = 0;
      next;
    }
  } else {
    if ($fence_type eq 'bt' && $L[$i] =~ /^[ ]{0,3}${BT}{3,}/) {
      $in_fence = 0; $fence_type = '';
      $is_body[$i] = 0;
      next;
    }
    if ($fence_type eq 'tilde' && $L[$i] =~ /^[ ]{0,3}~{3,}/) {
      $in_fence = 0; $fence_type = '';
      $is_body[$i] = 0;
      next;
    }
    $is_body[$i] = 0;
    next;
  }
  # 表格行：行首（含前置空白）是 |，或整行含 2 個以上 |（無前導豎線的表格列）
  my $pipe_count = () = $L[$i] =~ /\|/g;
  if ($L[$i] =~ /^\s*\|/ || $pipe_count >= 2) { $is_body[$i] = 0; next; }
  $is_body[$i] = 1;
}

# ---------- 檢查二：符號串接 ----------
# → ＋ ＝ 任意出現；／ 與 & 只抓兩側都是中文字或英數（不抓路徑／URL，
# 因為路徑用半形 /，這裡只比對全形 ／）；比照檢查三，另去除 inline code。
my $sym_re = qr/→|＋|＝|[\p{Han}A-Za-z0-9]／[\p{Han}A-Za-z0-9]|\p{Han}&\p{Han}/;
my @sym_hits;
for (my $i = 1; $i <= $n; $i++) {
  next unless $is_body[$i];
  my $line = mask_line($L[$i]);
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
  $msg .= "\n  （表達步驟或流程順序的「A → B → C」序列、數學式與 notation 可忽略）";
  push @issues, $msg;
}

# ---------- 檢查三：破折號與分號（正文行，另去除 inline code）----------
my $dash_count = 0;
my $semi_count = 0;
my @hit_lines;
for (my $i = 1; $i <= $n; $i++) {
  next unless $is_body[$i];
  my $line = mask_line($L[$i]);
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
  push @issues, "破折號 ${dash_count} 處、分號 ${semi_count} 處：確認是否過量或用來串接獨立主張；平列分句可用分號。\n  出現於：${lines_str}";
}

if (@issues) {
  print join("\n\n", map { "⚠️  $_" } @issues), "\n";
}
PERL_SCRIPT
)"
  rc=$?

  if [[ $rc -ne 0 ]]; then
    runtime_error=1
    found=1
    echo "⚠️ 無法完成文件形狀檢查（perl 執行失敗）：$f"
    continue
  fi

  if [[ -n "$result" ]]; then
    found=1
    echo "檔案：$f"
    echo "$result"
    echo
  fi
done

if [[ "$runtime_error" -eq 1 ]]; then
  exit 2
fi

if [[ "$checked_any" -eq 1 && "$found" -eq 0 ]]; then
  echo "✅ 未發現文件形狀問題"
fi
exit "$found"
