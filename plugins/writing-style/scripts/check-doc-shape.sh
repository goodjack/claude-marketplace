#!/usr/bin/env bash
# 文件形狀檢查：掃描 .md 檔案，抓「模型讀了規則也守不住」的文件形狀問題。
# 用法：check-doc-shape.sh <檔案...>
# 定位：警示工具（人工判斷），可掛 PostToolUse hook 當確定性防線。
# 只檢查 .md 檔；其他副檔名（或不存在的路徑）直接跳過，不輸出任何內容。
#
# 檢查項目（一至四、七預設啟用；五、六需設環境變數才啟用）：
#   1. 開頭長度——去掉 YAML frontmatter 與第一行 H1 後，從第一個非空行到
#      第一個 "## " 之前的文字，超過門檻就提醒搬去小節。
#   2. 符號串接——正文（排除 code fence ``` 與 ~~~／表格／frontmatter／單雙
#      反引號 inline code／URL）用 → ＋ ＝ ／ & 串接語意關係，而非寫成完整
#      句子；「A → B → C」流程序列與數學式 notation 不算，訊息末尾會註明。
#      命中摘錄取觸發符號前後各 15 字，不是行首 40 字，確保看得到觸發符號。
#   3. 破折號與分號——正文（同上遮罩規則）用 —— ── — ； ; 斷句過量，訊息
#      是軟性提醒（確認是否過量／可能是合理的平列分句），不是強制改句號。
#   4. 圖區塊名稱——code fence 語言標記是 diagram、dot、gv、viz 這類在
#      CodiMD／HackMD 不一定會畫成圖的名稱，提醒改用 graphviz 或 mermaid。
#   5. Mermaid 相容（預設不啟用）——只有設了 WRITING_STYLE_MERMAID_TARGET
#      （例如 8.10）且主版號小於 9 才檢查 mermaid 區塊：沒加雙引號卻含全形
#      標點（，（）：）的方框或箭頭標籤、--- 開頭的 frontmatter、@{ shape: … }。
#      設為 9 以上或未設時完全不檢查，新版語法不當錯誤。
#   6. 給人讀的部分長度——第一個 "## " 之後，找第一條後接固定分界句的水平線（--- 或
#      ***，不含 frontmatter 與 code fence 內）：線後第一個非空行以「以下供查證」開頭
#      （SKILL.md 規定的寫法）。量這條線之前的去空白字元數（code fence 內不算），超過
#      WRITING_STYLE_HUMAN_PART_LIMIT 就提醒。預設不啟用：只有設了這個環境變數
#      （例如 1500，團隊想自訂上限時）才檢查，未設完全不輸出。沒有固定分界句不套這項預算。
#   7. 段落長度——只檢查正文段落（排除 frontmatter、code fence、表格、標題行；
#      多行段落合併成一段，空行分段）。條列項目不檢查，連同它的接續行與項目內段落
#      一併略過（條列本來就是逐項掃讀）。去空白後（連結只算文字、不算網址；行內程式碼
#      含反引號整段不計）超過 WRITING_STYLE_PARAGRAPH_LIMIT（預設 120）就列出，
#      最多 5 處加「…另 N 處」。
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
HUMAN_PART_LIMIT="${WRITING_STYLE_HUMAN_PART_LIMIT:-}"
PARAGRAPH_LIMIT="${WRITING_STYLE_PARAGRAPH_LIMIT:-120}"

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

  result="$(SYNC_LAYER_LIMIT="$SYNC_LAYER_LIMIT" HUMAN_PART_LIMIT="$HUMAN_PART_LIMIT" PARAGRAPH_LIMIT="$PARAGRAPH_LIMIT" WRITING_STYLE_MERMAID_TARGET="${WRITING_STYLE_MERMAID_TARGET:-}" perl - "$f" <<'PERL_SCRIPT'
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

# 開頭起點：H1 之後的第一個非空行；沒有 H1 就是 frontmatter 後第一個非空行
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
    push @issues, "開頭 ${sync_len} 字元，超過 ${LIMIT}：沒有小節分隔，整份都算在開頭。";
  }
} else {
  if ($sync_len > $LIMIT) {
    push @issues, "開頭（第一個 ## 之前）${sync_len} 字元，超過 ${LIMIT}：開頭只放結論、已決定的事、要讀者做的事、哪裡可以停；其餘後置到 ## 小節，不是刪掉。";
  }
}

# ---------- 正文行判定：排除 frontmatter／code fence／表格 ----------
# fence 前置 0–3 個空白都算（CommonMark 慣例）；關閉 fence 要同字元、長度不小於開頭；``` 只能被 ``` 關閉、
# ~~~ 只能被 ~~~ 關閉，不同字元不互相配對、不會誤關。
my @is_body = (0) x ($n + 1);
my $in_fence = 0;
my $fence_type = '';
my $fence_len = 0;
for (my $i = 1; $i <= $n; $i++) {
  if ($fm_end && $i <= $fm_end) { $is_body[$i] = 0; next; }
  if (!$in_fence) {
    if ($L[$i] =~ /^[ ]{0,3}(${BT}{3,})/) {
      $in_fence = 1; $fence_type = 'bt'; $fence_len = length($1);
      $is_body[$i] = 0;
      next;
    }
    if ($L[$i] =~ /^[ ]{0,3}(~{3,})/) {
      $in_fence = 1; $fence_type = 'tilde'; $fence_len = length($1);
      $is_body[$i] = 0;
      next;
    }
  } else {
    if ($fence_type eq 'bt' && $L[$i] =~ /^[ ]{0,3}(${BT}{3,})\s*$/ && length($1) >= $fence_len) {
      $in_fence = 0; $fence_type = '';
      $is_body[$i] = 0;
      next;
    }
    if ($fence_type eq 'tilde' && $L[$i] =~ /^[ ]{0,3}(~{3,})\s*$/ && length($1) >= $fence_len) {
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

# ---------- 檢查四：圖區塊名稱 ----------
# CodiMD／HackMD 只認 graphviz、mermaid 等名稱；diagram、dot 之類會顯示成程式碼。
# ---------- 檢查五：Mermaid 相容（僅 WRITING_STYLE_MERMAID_TARGET 主版號 < 9 時）----------
{
  my $target = $ENV{WRITING_STYLE_MERMAID_TARGET};
  my $mm_check = (defined $target && $target =~ /^\s*(\d+)/ && $1 < 9) ? 1 : 0;
  my %bad_names;
  my @mm_hits;
  my $fence = '';      # '' 表示不在 fence 內；否則是目前 fence 的語言（小寫）
  my $fence_ch = '';
  my $fence_n = 0;
  my $mm_first = 0;
  for (my $i = 1; $i <= $n; $i++) {
    my $line = $L[$i];
    if ($fm_end && $i <= $fm_end) { next; }
    if ($fence_ch eq '') {
      if ($line =~ /^[ ]{0,3}(${BT}{3,}|~{3,})\s*([^\s${BT}]*)/) {
        $fence_ch = substr($1, 0, 1);
        $fence_n = length($1);
        $fence = lc($2);
        $mm_first = 1;
        $bad_names{$fence}++ if $fence =~ /^(?:diagram|dot|gv|viz)$/;
      }
      next;
    }
    if ($line =~ /^[ ]{0,3}(\Q$fence_ch\E{3,})\s*$/ && length($1) >= $fence_n) { $fence_ch = ''; $fence = ''; next; }
    next unless $mm_check && $fence eq 'mermaid';
    next if $line =~ /^\s*$/;
    if ($mm_first) {
      $mm_first = 0;
      if ($line =~ /^\s*---\s*$/) { push @mm_hits, "  第 ${i} 行：以 --- 開頭的 frontmatter（舊版不支援）"; next; }
    }
    next if $line =~ /^\s*%%/;
    if ($line =~ /\@\{\s*shape\s*:/) { push @mm_hits, "  第 ${i} 行：\@{ shape: … } 語法（新版才有）"; }
    my $t = $line;
    $t =~ s/\x22[^\x22]*\x22//g;  # 去雙引號字串；用 \x22 避免舊版 bash 解析 heredoc 時引號配對失敗
    if ($t =~ /\[[^\]]*[，（）：][^\]]*\]|\x28[^\x29]*[，（）：][^\x29]*\x29|\{[^}]*[，（）：][^}]*\}|\|[^|]*[，（）：][^|]*\|/) {
      my $ex = $line; $ex =~ s/^\s+//;
      push @mm_hits, "  第 ${i} 行：標籤含全形標點卻沒加雙引號，改成 A[\"…\"] 或 -->|\"…\"|：" . substr($ex, 0, 30);
    }
  }
  if (%bad_names) {
    my $names = join('、', map { "${BT}${BT}${BT}$_ ($bad_names{$_} 個)" } sort keys %bad_names);
    push @issues, "圖區塊名稱 ${names}：CodiMD／HackMD 不一定會畫成圖，讀者可能只看到程式碼。改用 ${BT}${BT}${BT}graphviz 或 ${BT}${BT}${BT}mermaid。";
  }
  if (@mm_hits) {
    my $total = scalar(@mm_hits);
    my @shown = @mm_hits;
    my $extra = 0;
    if ($total > 5) { @shown = @mm_hits[0..4]; $extra = $total - 5; }
    my $msg = "Mermaid 圖有 ${total} 處在 Mermaid ${target} 可能畫不出來（WRITING_STYLE_MERMAID_TARGET）：\n" . join("\n", @shown);
    $msg .= "\n  …另 ${extra} 處" if $extra > 0;
    push @issues, $msg;
  }
}

# ---------- 檢查六：給人讀的部分長度（第一個 ## 到分隔線之間）----------
{
  my $hl = $ENV{HUMAN_PART_LIMIT};
  $hl = (defined $hl && $hl =~ /^\d+$/ && $hl > 0) ? $hl : 0;   # 未設或非正整數：不檢查
  my @code = (0) x ($n + 2);
  my $fch = '';
  my $fn = 0;
  for (my $i = 1; $i <= $n; $i++) {
    if ($fm_end && $i <= $fm_end) { next; }
    if ($fch eq '') {
      if ($L[$i] =~ /^[ ]{0,3}(${BT}{3,})/) { $fch = $BT; $fn = length($1); $code[$i] = 1; }
      elsif ($L[$i] =~ /^[ ]{0,3}(~{3,})/) { $fch = '~'; $fn = length($1); $code[$i] = 1; }
      next;
    }
    $code[$i] = 1;
    if ($L[$i] =~ /^[ ]{0,3}(\Q$fch\E{3,})\s*$/ && length($1) >= $fn) { $fch = ''; }
  }
  my $sep = 0;
  if ($first_h2) {
    for (my $i = $first_h2 + 1; $i <= $n; $i++) {
      next if $code[$i];
      next unless $L[$i] =~ /^[ ]{0,3}(?:-{3,}|\*{3,})\s*$/;
      my $k = $i + 1;
      while ($k <= $n && $L[$k] =~ /^\s*$/) { $k++; }
      # 只認 SKILL.md 規定的固定分界句：分隔線後第一個非空行以「以下供查證」開頭
      # （前面可有粗體或斜體記號）。關鍵詞猜測會把一般操作句誤認成分界，故不採用。
      if ($k <= $n && $L[$k] =~ /^\s*[*_]*\s*以下供查證/) { $sep = $i; last; }
    }
  }
  my $has_after = 0;
  if ($sep) {
    for (my $i = $sep + 1; $i <= $n; $i++) {
      if ($L[$i] !~ /^\s*$/) { $has_after = 1; last; }
    }
  }
  if ($hl && $sep && $has_after) {
    my $cnt = 0;
    for (my $i = $first_h2 + 1; $i < $sep; $i++) {
      next if $code[$i];
      my $t = $L[$i];
      $t =~ s/\s+//g;
      $cnt += length($t);
    }
    if ($cnt > $hl) {
      push @issues, "給人讀的部分 ${cnt} 字，超過約一頁（${hl}）：把證據細節移到查證用的部分，主線每個結論只留一句證據摘要與它的限制；會改變判斷的限制不能刪。";
    }
  }
}

# ---------- 檢查七：段落長度（只檢查段落，條列項目不檢查）----------
{
  my $pl = $ENV{PARAGRAPH_LIMIT};
  $pl = 120 unless defined $pl && $pl =~ /^\d+$/ && $pl > 0;
  my @long;
  my $cur = '';
  my $cur_start = 0;
  my $flush = sub {
    if ($cur_start) {
      my $t = $cur;
      $t =~ s/\Q$BT2\E.*?\Q$BT2\E//g;        # 行內程式碼整段不計（先雙後單，同 mask_line）
      $t =~ s/\Q$BT\E[^$BT]*\Q$BT\E//g;
      $t =~ s/\]\x28[^\x29]*\x29/]/g;
      $t =~ s/<https?:[^>]*>//g;
      $t =~ s{https?://[^\s\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}（）「」『』、，。；：！？]+}{}g;
      $t =~ s/\s+//g;
      my $len = length($t);
      push @long, [$cur_start, $len] if $len > $pl;
    }
    $cur = '';
    $cur_start = 0;
  };
  # 條列項目的判定：項目符號行開始一個項目；之後沒有空行隔開的行是它的接續行，
  # 空行之後縮排達到項目內容起點的行是項目內的後續段落，兩者都不算一般段落。
  my $in_item = 0;
  my $list_min = 0;      # 目前這串條列的內容縮排下限（取各項目的最小值）
  my $prev_blank = 0;
  for (my $i = 1; $i <= $n; $i++) {
    my $line = $L[$i];
    if ($line =~ /^\s*$/) {
      $flush->();
      $prev_blank = 1;
      next;
    }
    if (!$is_body[$i] || $line =~ /^\s{0,3}[#]{1,6}(?:\s|$)/ || $line =~ /^[ ]{0,3}(?:-{3,}|\*{3,}|_{3,})\s*$/) {
      $flush->();
      # 項目內縮排的 code fence 或表格不中斷這個項目；標題、分隔線與頂格的非正文行才中斷
      my $is_block = $line =~ /^\s{0,3}[#]{1,6}(?:\s|$)/ || $line =~ /^[ ]{0,3}(?:-{3,}|\*{3,}|_{3,})\s*$/;
      (my $ws = $line) =~ s/^(\s*).*$/$1/;
      $ws =~ s/\t/    /g;
      $in_item = 0 if $is_block || length($ws) < $list_min;
      $prev_blank = 0;
      next;
    }
    $line =~ s/^\s*>+\s*//;
    if ($line =~ /^(\s*(?:[-*+]|\d+[.\x29])\s+)/) {
      my $prefix_len = length($1);
      $flush->();
      $list_min = (!$in_item || $prefix_len < $list_min) ? $prefix_len : $list_min;
      $in_item = 1;
      $prev_blank = 0;
      next;
    }
    if ($in_item) {
      (my $ws = $line) =~ s/^(\s*).*$/$1/;
      $ws =~ s/\t/    /g;
      if (!$prev_blank || length($ws) >= $list_min) {
        $prev_blank = 0;
        next;
      }
      $in_item = 0;
    }
    $prev_blank = 0;
    $cur_start = $i unless $cur_start;
    $cur .= $line;
  }
  $flush->();
  if (@long) {
    my $total = scalar(@long);
    my @shown = @long;
    my $extra = 0;
    if ($total > 5) { @shown = @long[0..4]; $extra = $total - 5; }
    my $lines_str = join('、', map { "第$_->[0]行（$_->[1] 字）" } @shown);
    $lines_str .= "、…另 ${extra} 處" if $extra > 0;
    push @issues, "段落超過約畫面三行（門檻 ${pl} 字）：拆成兩段或把細節移到後面，不要切斷因果；指令與路徑放程式碼區塊。\n  出現於：${lines_str}";
  }
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
