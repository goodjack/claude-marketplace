# 設計決策與證據狀態

本檔記錄 `SKILL.md` 各條規則的**正當性來源**：哪些是本 skill 的設計決策、哪些從外部依據推導、哪些查過但不採用。

## 目錄

依「可動範圍」由嚴到寬排序：

1. **覆核這個 skill 時的規則**——四類正當性來源各自能改什麼、重開條件。
2. **設計決策 WS-D01～D09**——不可因外部依據變動而改。
3. **混合型決策 WS-M01～M08**——行為目標不可動，實作細節（數字、門檻）可調。
4. **外部依據**——可依新證據修改。
5. **已否決的主張**——不得因為在寫作圈流行就加回。
6. **平台與渲染細節**。
7. **句子層細則的證據身分**——`examples.md`「句子與條列的寫法」那六條的查證結果。

同目錄另有 `examples.md`（語氣變體、正反例全集、AI 常犯問題的判斷細節）與 `taiwan-terms.md`（中國用語對照表）。

## 覆核這個 skill 時的規則

**先讀完本檔再提出任何刪改。** 規則的正當性來源不同，可動的範圍就不同：

| 正當性來源 | 外部依據失效時可以做什麼 | 不可以做什麼 |
| --- | --- | --- |
| 設計決策 | 修正引用、更新理由、提出重開建議 | 改掉或降級「不變條件」 |
| 混合型（本地採納＋外部旁證） | 同上，另可調整實作細節（數字、門檻、措辭） | 改掉行為目標本身 |
| 外部依據推導 | 依新證據修改或刪除 | 無額外的決策保護，但仍須符合成功標準、既有設計決策與正確性要求 |
| 來源不明 | 先查 git log、既有紀錄或詢問維護者 | 預設當成外部推導規則直接刪改 |

**依據站不住不等於規則要改。** 設計決策的正當性來自使用需求，引用只是佐證；引用失效的正確處置是撤掉引用，規則不動。

重開條件（任一成立即可重新討論，不必等全部滿足）：

- 維護者明確表示需求或主要使用情境已改變。
- 這個決策造成正確性、安全或無障礙問題——一個可信案例即可重開。
- 在兩份不同的實際產出中，重複造成相同的理解或使用失敗。
- skill 的目標讀者、觸發範圍或定位改變。
- 替代方案經新舊產出比較，能保留原目標並明顯改善結果。

外部 guide 更新、引用失效、reviewer 偏好不同，可以觸發證據覆核，但不能自動翻轉設計決策；有疑似衝突就提重開建議交維護者裁決。

本檔記錄的是**目前有效的約束**，不是修訂歷史——歷史交給 git log。

## 設計決策

### WS-D01：預設採掃讀型

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求。
- **不變條件**：未命中明確例外時，產出必須提供可掃讀路徑。
- **可調部分**：標題命名、條列層數、表格與條列的選擇、句長提示。
- **理由**：主要使用情境幾乎都需要快速且精準地掌握資訊；未明示時，模型常輸出不利掃讀的長段落。
- **與外部依據的關係**：外部研究可以改善做法，但不決定是否採用這個預設。原本引用的「79% 讀者掃讀」已撤除（理由見「已否決的主張」），撤除不影響本決策。
- **日期**：2026-07-16 定，2026-07-27 再確認。

### WS-D02：文體判準跟著讀者的使用方式走

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求。
- **不變條件**：反覆查閱、跨文件比對的文件一律掃讀型（報告、決策紀錄、狀態檔、規格、稽核）；論述型只限一次性完整閱讀的說服內容。
- **可調部分**：哪些文件類型歸哪一邊的清單。
- **理由**：用「內容怎麼產生」分類會把需要反覆查閱的文件寫成長篇論述，讀者每次回來都要重讀。
- **日期**：2026-07-19 定。

### WS-D03：台灣正體中文、台灣慣用語、自然的中英混用

- **狀態**：有效。
- **正當性來源**：本 skill 的定位，不是外部 style guide 推導。
- **不變條件**：不使用中國用語；台灣工程實務慣用英文的詞不硬翻成生造中文。**這條保護的是用詞習慣，不豁免術語階梯**——保留英文之後，讀者不熟時一樣要補白話說明，需要搜尋或溝通時保留正式英文名稱。
- **可調部分**：詞表內容（見 `taiwan-terms.md`）。

### WS-D04：目標讀者的實際回饋優先於通用指南

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求。
- **不變條件**：讀者說難讀就調整，不拿 style guide 壓讀者。
- **理由**：通用 guide 服務的是通用讀者，這份 skill 服務的是特定使用情境。

### WS-D05：研究型產出的讀者知識預設

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求，來自實際失敗——研究陌生領域後產出的報告滿篇該領域術語，委託研究的人讀不懂。
- **不變條件**：研究與調查型產出的預設讀者不熟該領域。陌生術語不得阻礙理解，同時要保留可供搜尋與跟人討論的正式名稱。
- **可調部分**：處理階梯的步驟、白話說明的寫法、建 glossary 的門檻。
- **理由**：委託研究這件事本身就是不熟的訊號。模型讀完大量來源文獻後會沿用來源的用語，這個傾向要靠規則抵銷，不能靠自覺。
- **與外部依據的關係**：四份 style guide 的術語處理階梯是做法來源與佐證，但這個結果要求不因外部 guide 更新而刪除。
- **日期**：2026-07-27。

### WS-D06：可見主線優先服務當前任務

- **狀態**：有效。
- **正當性來源**：實際使用回饋與本 skill 的設計需求。不是從 GitHub 的 `<details>` 文件推導——那份文件只支撐摺疊怎麼用，撐不起四類分流、處理順序與三項否決條件。
- **不變條件**：可見主線優先服務讀者的當前任務；背景、例外與參考資料不得擋在必要判斷與最短成功路徑之前。
- **可調部分**：四類分流的名稱與邊界、摺疊的條件、最長區塊抽查的數量。
- **理由**：實跑一份導入教學時，局部規則全數合格（每項自我完整、每段一個推論單位、術語都有解釋），讀者仍回饋「字很多很難讀」。原因是內部機制與詞彙表擋在第一次成功之前——第一次實際操作到第 147 行才出現。規範原本只檢查每一段寫得好不好，沒有檢查這段現在該不該出現。
- **外部依據的關係**：雙模型各自跑過 consensus 查證，結論一致——底層原則有支持（Diátaxis 的 tutorial 要先給可見成果並把 explanation 移出、DITA 的 task／concept／reference 分型、GOV.UK 要求內容回應實際使用者需求、W3C 要求非主要目的的內容與主線分離），但**四類分流本身沒有任何框架採用相同切法**，它混合了「內容用途」與「在當前流程的位置」兩條軸線。所以這是有理據的本地決策，不能宣稱它是 Diátaxis 或 DITA 的分類法。
- **邊界**：「最短成功路徑」不等於無條件追求步驟最少。真正必要的 prerequisite 仍應放在操作之前（DITA、Write the Docs 立場），Diátaxis 的 tutorial 也是學習經驗而非最快完成任務。
- **日期**：2026-07-27。

### WS-D07：人稱跟著文件流通範圍走

- **狀態**：有效。
- **正當性來源**：維護者 2026-08-08 定案的設計決策，來自實際分享版的定型經驗。
- **不變條件**：點對點、明確收發者的訊息與信件保留人稱；預期被轉發、脫離對話脈絡流通的分享版與簡報材料用無人稱事實句；owner、責任、決策者會影響行動時人名照寫（無人稱管文法人稱，不管責任歸屬）。
- **可調部分**：無人稱句型的示例、「預期被轉發」的判斷提示。
- **理由**：「我／你」在第三者手上指涉錯亂——無人稱的依據是轉發時的功能需求，不是任何寫作傳統的權威要求。
- **與外部依據的關係**：兩側各有佐證，強度不同。美軍 AR 25-50《Preparing and Managing Correspondence》第 1-39.b.(6) 段建議 correspondence 用 I、you、we 當句子主詞（支持「點對點保留人稱」側；查證時 .mil 官方網域連線失敗，經第三方鏡射 armywriter.com 以修訂日期交叉核對，有方法折扣）。Amazon 6-pager 文件刻意不具名、範本句無人稱（出自前員工文章，屬社群來源非官方；只能證明匿名慣例本身，不能證明動機是轉發——相鄰案例，不當作轉發判準的正向證據）。**引用紀律：不得宣稱無人稱繼承自 BLUF 或 briefing note 傳統**（理由見「已否決的主張」）。
- **日期**：2026-08-08。

### WS-D08：內部完整版轉分享版必跑裁切流程與外流檢查

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求，來自實際失敗——內部版附錄放著給對方本人的訊息草稿，分享版差點原樣傳給對方本人。
- **不變條件**：內部完整版是唯一事實來源，分享版是裁切產物；轉分享版必跑外流檢查，清單至少含收件人無權取得的內容（個資、機密、憑證與 secret、內部識別）、內部狀態行、內部連結、給對方本人的草稿、AI 協作痕跡、frontmatter。
- **可調部分**：六步流程的排序與措辭、檢查清單的項目增補。
- **日期**：2026-08-08。

### WS-D09：每份文件開頭有受硬上限的同步層

- **狀態**：有效。
- **正當性來源**：維護者 2026-09-02 定案的設計決策，來自實際回饋——2.x 各版改善了單份文件內部的寫法，總量卻沒降（兩次行為對照新版都比舊版長），使用者仍覺得「很多字、很長」。診斷：既有的減法規則（刪背景、移細節、略過不適用的節）都是判斷題、沒有門檻，沒有任何規則對可見層設上限，拉扯時一律輸給「不失真」側。
- **不變條件**：文件開頭（標題之後、第一個 `##` 之前）是同步層，只放結論或現況、已決定的事、要讀者做的事、哪裡可以停（四項依文件需要選用）；同步層有硬上限；放不進去的內容一律落到展開層（後置小節、附錄、拆檔），不得因此刪除。同步層不得出現本文件首次定義的術語。
- **可調部分**：上限數字（目前規則寫 5 個主張、hook 量 400 字元，後者約等於一分鐘的中文閱讀量，只是換算說明。這是維護者採用的**實驗初始值**，不是外部共識，待用實際文件 A/B 校準：首次拿到可執行結論的時間、能否安全停讀、有沒有漏掉關鍵但書）、四項的名稱與順序、展開層的排序細則。
- **與 WS-M01 的關係**：不衝突。WS-M01 保護的是「不可刪」，本條做的是「移」。**與「已否決的主張：任何固定的段落句數上限」的差別**：被否決的是約束句段內部形式的數字（會誘導砍限定語湊字數）；本條約束的是可見層的主張總量並強制指定去處，限定語跟著主張走、算同一個主張。覆核時不得拿那條否決來刪本條。
- **證據身分（全部是類比或本地推論，沒有任何來源直接支持同步層架構或 5／400 這組數字）**：[AR 25-50](https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN42124-AR_25-50-007-WEB-13.pdf) §1-39b(7) 規範的是美軍公文「多數一頁、附加資訊走 enclosure」，只支持「受限主文加附件」這個形狀；[Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)「Written deliverable length」只支持明確校準長度並刪除填充，不給數字；[LIFEBench](https://arxiv.org/abs/2505.16234) 只顯示短長度指示比長的容易遵循，支持把數字放在小的同步層。Basecamp、GitLab、Stripe 的寫作規範查無字數上限。數字是本地決策。
- **失敗模式與執行層**：硬上限可能 Goodhart——砍限定語、或用多層子句把主張塞進一句以通過字數檢查；防守靠仲裁表「移走整個主張、不拆限定語」與驗收列的明文禁止，沒有研究量過「為達標砍掉的是填充還是實質」。2026-08-11 的對照只直接觀測到符號與標點：靠 prompt 守不穩、進 hook 才穩；同步層長度能否靠 prompt 守住仍待 A/B。同步層字元數與符號串接由 `scripts/check-doc-shape-hook.sh` 檢查，只警示、不阻擋、不截斷；語意層的判斷（哪個主張可以移、哪個但書必須留）留在 prompt。
- **日期**：2026-09-02。

## 混合型決策

行為目標是本地採納的設計決策，外部資料只是佐證。**行為目標不可因外部依據變動而改；實作細節（數字、門檻）可調。**

| 編號 | 行為目標（不可動） | 可調部分 | 佐證 |
| --- | --- | --- | --- |
| WS-M01 | 不可為了短而刪掉理解所需的內容。**同步層預算（WS-D09）與此不衝突：它做的是「移到展開層」，不是刪** | 具體的重讀觸發器怎麼寫 | plain language 系原則；W3C COGA 4.4.9、4.4.12；兩篇 LLM 研究（細節見表後） |
| WS-M02 | 「一句一事」限制的是主張數量，不是字數 | 判斷主張數量的提示 | 同上 |
| WS-M03 | 說明型條列每項自我完整，不逼讀者回查前文 | 例外情境 | COGA「不依賴記憶」目標 |
| WS-M04 | 先認定讀者，再決定機制要解釋到多深 | 讀者分類方式 | plain language「write for your audience」 |
| WS-M05 | 縮寫與代號首次出現附意義 | 豁免清單 | Google／Microsoft 縮寫規範 |
| WS-M06 | 跨文件引用要說明目前狀態，不只丟連結 | 狀態聲明的格式 | W3C「Status of This Document」慣例（**類比**，不是直接證據——該慣例規範的是 W3C 規格文件，不是一般跨文件引用） |
| WS-M07 | 長篇報告要讓不同閱讀深度的人都拿到核心資訊：執行摘要能脫離全文獨立閱讀，非必要的查證材料不擋在正文 | 是否設附錄、各層名稱、摘要長度 | 現行工程報告慣例（[IEEE: Write Effective Reports](https://procomm.ieee.org/communication-resources-for-engineers/written-reports/write-effective-reports/)）區分 executive summary、body、appendices，是最直接的支持；適用邊界見表後 |
| WS-M08 | 分享版詞彙以與對方共同場合出現過的詞為界 | 「共同場合」的認定方式、白名單外術語的處置 | plain language 三方官方一致的「write for your audience」（[digital.gov](https://digital.gov/guides/plain-language/principles/write-for-reader)、[GOV.UK](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)、EU《How to write clearly》）；「以共同場合出現過的詞為界」的操作法是本地強化，官方原文沒有這個界線 |

這批來自實際文件的讀者回饋，使用者已採納修正。**注意**：採納「不可為了短而刪內容」不等於凍結所有相關數字——20 字、40 字這類實作數字不在保護範圍。

佐證欄的查證細節（儲存格只留摘要，細節放這裡）：

- **WS-M01 的兩篇 LLM 研究**：LLM 摘要出現廣泛概化的比率高於人類科學摘要（[Peters & Chin-Yee, 2025](https://doi.org/10.1098/rsos.241776)，4,900 份摘要、10 個模型，odds ratio 4.85；限科學與醫學摘要，不外推為所有文件的固定風險率）；即使 prompt 指定目標讀者，模型輸出的可讀性範圍仍難調動（[arXiv 2312.02065](https://arxiv.org/abs/2312.02065)）。
- **WS-M07 的適用邊界**：**ISO 5966 已於 2000 年撤銷**，只能當歷史來源，不可當現行標準引用。IEEE 只說執行摘要最長約可到全文 10%，「5–10%」是誤植，本 skill 不寫死比例。[Minto](https://www.barbaraminto.com/) 支持的是「主要結論在上、支持論點在下，上層概括其下層論點」的**論點階層**，不直接主張「同一份文件分層服務不同角色」，兩者不要混為一談。PNAS 的三層規範（Significance Statement 120 字給大眾、Abstract 給同行、全文）是少數有明文字數的案例，可參考不可外推。

## 外部依據（可依新證據修改）

以下規則的正當性來自外部規範，證據變動就跟著調整；表內標注「本地加註」「本地推導」「本地補充」的部分是本地決策，不隨外部證據變動：

| 規則 | 來源 | 適用範圍與注意事項 |
| --- | --- | --- |
| 每項 3 個以上屬性要對照就用表格 | [Google Style Guide: Tables](https://developers.google.com/style/tables) | 判準看屬性數不看項目數。本 skill 另加輔具、窄螢幕、儲存格過長三個例外，屬本地加註，不是原始來源的立場 |
| 清單 2–7 項 | [Microsoft Style Guide: Lists](https://learn.microsoft.com/en-us/style-guide/scannable-content/lists) | 官方寫的是建議值。其常被連結的 Miller 7±2 在認知科學界已被視為過度簡化，不要拿來當科學依據 |
| 只有 1~2 列不要做表格 | [Australian Style Manual: Tables](https://www.stylemanual.gov.au/structuring-content/tables) | 「表頭比內容重」是本地補充的理由，原文沒有 |
| 名詞連用三個以上就難讀 | [digital.gov: Plain language — writing style](https://digital.gov/guides/plain-language/writing/style)（plainlanguage.gov 原頁已於搬遷後併入，舊網址 301） | 門檻確為 3，原文措辭更強（beyond three, the string becomes unbearable） |
| 斜線不可分隔替代選項、`&` 不可代 and | [Google: Slashes](https://developers.google.com/style/slashes)、[Word list](https://developers.google.com/style/word-list) | `&` 規則對 UI 元件、表頭、程式碼有例外 |
| 術語處理階梯（能換就換 → 保留＋首次說明 → 大型文件才建 glossary） | [Google: Jargon](https://developers.google.com/style/jargon)、[Microsoft: Use technical terms carefully](https://learn.microsoft.com/en-us/style-guide/word-choice/use-technical-terms-carefully)、[GOV.UK Technical A–Z](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/style-guides/technical-a-to-z/) | 前兩階有外部支持：各家都反對把必要術語砍光，Google 支持保留讀者會拿去搜尋的術語（原文是「readers search for those terms」與 SEO，非逐字 searchability）。**第三階「大型文件才建 glossary」是本地推導**：Google 與 Microsoft 該頁均未提 glossary（2026-08-02 查證），不能列為多家共同規則；規則保留，該階證據身分為本地 |
| 事件報告聚焦系統不聚焦個人，action item 要有 owner | [Google SRE Book: Postmortem Culture](https://sre.google/sre-book/postmortem-culture/) | 社群有「blame-aware」的修正意見，認為純 blameless 不符合人的實際反應 |
| 標點規範 | 教育部《重訂標點符號手冊》修訂版（2009） | 台灣現行的官方標點規範。不採 GB/T 15834——兩岸的分號定義、引號、標點位置有落差 |
| 摺疊區塊的語法與基本用法 | [GitHub Docs: Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections) | 只支撐「怎麼用」。本 skill 的四類分流、處理順序與三項否決條件屬 WS-D06，不是從這份文件推導 |
| 重要資訊不得藏在摺疊裡 | [NN/g: Accordions on Desktop](https://www.nngroup.com/articles/accordions-on-desktop/)、[GOV.UK Details](https://design-system.service.gov.uk/components/details/)、[GOV.UK Accordion](https://design-system.service.gov.uk/components/accordion/) | NN/g：「Avoid hiding any crucial information within the collapsed panels」。GOV.UK 更嚴：details 只適合部分使用者需要的資訊；所有人都需要的內容應該先試簡化或拆頁，不是收合 |
| 教學先讓讀者動手、背景不擋路 | [Diátaxis: Tutorials](https://diataxis.fr/tutorials/) | 主要支持是 Diátaxis。Google Procedures 只規範步驟寫法，且要求讀者能事先取得準備任務所需的資訊——歸在「必要 prerequisite 放操作前」那一側，不能並列為本規則的共同支持（2026-08-02 更正）。**不是無條件追求步驟最少**。[DITA task elements](https://docs.oasis-open.org/dita/v1.1/OS/langspec/common/task2.html) 與 [Write the Docs](https://www.writethedocs.org/guide/writing/docs-principles/) 支持把真正必要的 prerequisite 放在操作之前。查過 Google、Microsoft、DITA、Diátaxis、W3C，**沒有**任何一家主張完整詞彙表該放教學前面 |
| 一個步驟對應一個讀者決定 | [Google: Procedures](https://developers.google.com/style/procedures)、[Microsoft: Step-by-step instructions](https://learn.microsoft.com/en-us/style-guide/procedures-instructions/writing-step-by-step-instructions) | 兩家都允許把同一操作位置上的小動作合併，也允許步驟附帶必要結果或理由。**「每個項目只能含單一資訊」會過度切碎**，不是共識 |
| 連結節制 | NN/g「A Link is a Promise」、[Google: Cross-references](https://developers.google.com/style/cross-references) | Google 現行立場是把連結放在最有用的位置；長頁面、多入口時可以重複。正文的「預設只連首次」已寫入這個例外 |
| 一段一概念、不設固定句數 | [Google: Paragraph structure](https://developers.google.com/style/paragraph-structure) | 現行立場是一句或超過六句都可能合理。正文據此改用「一段一個推論單位」的可觀測判準 |
| 認知可及性 | [W3C COGA: Making Content Usable](https://www.w3.org/TR/coga-usable/design_guide.html) 4.4.1、4.4.3、4.4.5、4.4.8、4.4.9、4.4.12 | 屬補充指引，不是 WCAG 強制條款 |

## 已否決的主張

查過但**不採用**，且**不得因為在寫作圈流行就重新加回**。加回前請先讀「為什麼」欄。

| 主張 | 判定 | 為什麼不用 |
| --- | --- | --- |
| 「79% 讀者掃讀而非逐字讀」 | 已否決當作依據 | 出自 1997 年的 web 瀏覽研究，NN/g [2008 年已改用](https://www.nngroup.com/articles/how-little-do-users-read/)「平均只讀 20-28% 字數」的框架。兩組數字都是 web 行為，不能外推到工作文件。掃讀預設改由 WS-D01 支撐，不需要比例數字 |
| 「GOV.UK 規定段落上限 5 句」 | 外部確有此規範，本地不採用 | 2026-08-02 更正：GDS 官方指引確有「Paragraphs should have no more than 5 sentences each」（[Writing to GOV.UK standards](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)），先前判定「查無此出處」是查證錯誤——只查了主 style guide，漏了 publishing 指引；「查無來源」這類否定命題要查官方站內搜尋、現行頁面與搬移頁面才能下。句長 25 字的規定同頁並存。ONS service manual 另訂 4 句。規則不變（見下一列），只改證據身分 |
| 任何固定的段落句數上限 | 不採用（本地裁決） | 外部有規範但數字互不一致（GOV.UK 5 句、ONS 4 句、Google 不設數字），且固定數字會製造「為了符合形式而過度壓縮」的問題；使用者已裁決不用固定句數作硬門檻。改用「一段一個推論單位」的可觀測判準。**同步層預算（WS-D09）不在此列**：被否決的是約束句段內部形式的數字，WS-D09 約束的是可見層的主張總量並強制指定去處 |
| 「中文一句 20 字內最佳、40 字是上限」 | 查無來源 | 只找得到零星部落格的「15-25 字」建議，無學術或官方來源。改用可觀測的重讀觸發器取代字數門檻 |
| 「破折號堆疊是 AI 生成特徵」 | 降級為弱訊號 | 屬流行認知，會誤傷本來就慣用破折號的作者。破折號限量的理由改用可讀性（過量或關係不明會妨礙理解） |
| 「BLUF、inverted pyramid、Minto、GOV.UK 四個體系同向」 | 引用有誤 | HBR 2016 原文只提 BLUF 與 inverted pyramid 相似，沒提 Minto。Minto 的核心是歸納／演繹論證階層，跟純重要性排序不同。**否決的是「四體系同向」這個宣稱，不是 Minto 本身**——Minto 在「主要結論在上、上層概括其下層論點」這個論點階層的用途上仍是有效來源（見 WS-M07）。但它不直接支持「分層服務不同角色」，那是本地延伸 |
| 用 Diátaxis 當「讀者範圍」的分層依據 | 接錯軸 | Diátaxis 分的是讀者當下的需求情境（學習／解決問題／查閱／理解），不是讀者身份或知識程度 |
| 「無人稱語域是 BLUF／briefing note 的傳統要求」 | 引用有誤 | AR 25-50 第 1-39.b.(6) 明文要求 correspondence 用 I、you、we 當句子主詞，方向與無人稱相反；加拿大 briefing note 指南只規定內容客觀（不寫個人意見），不規範文法人稱——內容客觀性與文法人稱是兩條規則，不能混為一談。**否決的是歸屬宣稱，不是無人稱本身**：無人稱的正當性由 WS-D07 承載（轉發時指涉錯亂的功能依據），不掛任何權威傳統名下 |
| Jansen (2014) 的 bullet 研究可當無條件通則 | 過度簡化 | 原文是五個分研究的有條件結果：三個發現 bullet 有助清單記憶（項目異質時效果減弱）、兩個發現傷及周邊段落記憶，但讀者對文章整體評價反而更好 |
| Bionic Reading 式加粗（每個字前半段加粗） | 不採用 | 2024-2025 多篇對照研究（含眼動追蹤）未發現速度或理解上的效益，例如 [Acta Psychologica 2024](https://www.sciencedirect.com/science/article/pii/S0001691824001811)，部分研究另觀察到負面效果。泛稱「標記關鍵字有助聚焦」則屬社群主流、無直接對照實驗 |
| 用 WCAG 2.2 SC 3.1.5 Reading Level 當硬門檻 | 不採用 | 它是 web 的 AAA 條款，對一般文件過嚴；COGA 的條目對本 skill 更直接 |
| 用「3-30-300」當分層結構的名稱 | 不採用 | 這個名稱出自 [Kurt Buhler, SQLBI, 2024-06-03](https://www.sqlbi.com/articles/introducing-the-3-30-300-rule-for-better-reports/)，用於 Power BI 儀表板，概念源頭是 Shneiderman 1996 的 visual information-seeking mantra。原文的「30 秒」是 filter 與 zoom 這類互動操作，靜態文件沒有這個動作。本 skill 曾誤把它當成通用的文件寫作慣例，改用 Executive Summary → Body → Appendix（見外部依據表）。同名不同義的還有行銷的「3-30-3 rule」（末段是 3 分鐘）與都市林業的「3-30-300 rule」（3 棵樹、30% 樹冠、300 公尺綠地） |
| 讀者可讀性分數（Flesch-Kincaid 之類）當通過標準 | 不採用 | 屬工具與顧問慣例，非 plainlanguage.gov／GOV.UK 的規定；量化門檻容易變成新的形式主義 |

## 平台與渲染細節

`<details>/<summary>` 摺疊的相容性（會變動的支援資料指向來源，本檔不寫死版本號）：

- **元素本身的支援不是問題**：支援率與版本現況見 [caniuse](https://caniuse.com/details)（比例會變動，本檔不寫死）。CodiMD／HackMD、GitHub 與多數 IDE 預覽也都支援（HackMD／CodiMD × Chrome／Firefox 有使用者 2026-08-02 實測確認）。
- **Notion**：貼上或匯入 Markdown 時會移除標籤，內容可能整段消失，不會變成 toggle。其 API 另有支援 details/summary，但貼上、匯入、API 是三條不同通路，不能互相外推。確定要貼到 Notion 的文件先展開，改用「存查材料後置＋文末附錄」。
- **頁內搜尋找得到（這是修正過的認知）**：[HTML Standard](https://html.spec.whatwg.org/multipage/interaction.html#interaction-with-details-and-hidden=until-found) 把「頁內搜尋能找到關閉的 `<details>` 並自動展開」列為規範行為；各瀏覽器完成實作的時間不一（caniuse 的 details 條目未涵蓋此行為），目標環境有疑慮就實測。**「摺疊內容搜不到」對現代瀏覽器的原生 details 已不成立，不能再拿來當摺疊的否決條件。** Safari 曾有「展開但沒捲到結果」的問題，體驗仍可能不完整。
- **`hidden="until-found"` 是另一套機制**，各家支援狀態的公開資料曾互相矛盾；現況查 [caniuse](https://caniuse.com/mdn-html_global_attributes_hidden_until-found) 或 MDN，目標環境有疑慮就實測。
- **列印**：展開與否沒有一致保證。

## 句子層細則的證據身分

`examples.md`「句子與條列的寫法」的六條，證據強度不一，重寫時已依查證結果條件化（這六條原在 `SKILL.md`，重構時移入 `examples.md`）：

| 規則 | 證據身分 | 條件化的內容 |
| --- | --- | --- |
| 段落起手句給方向 | 部分支持 | [Google](https://developers.google.com/style/paragraph-structure) 支持重要資訊放段首，**不支持每段都要表態**。已改成分析論證先給主張、操作步驟先給動作、查閱型先給定義 |
| 有具體事實就不用抽象概括 | 部分支持 | 原措辭「數字與實例是說服力的本體」過度絕對，會誘導補入沒有來源的數字。已加上「前提是那個事實你手上真的有」 |
| 行動型文件收在下一步 | 本地慣例 | 不適用參考手冊、狀態紀錄與純說明文件。已限縮適用範圍 |
| 譬喻節制 | 自創門檻已移除 | 「一篇最多一兩個」查無共識來源。[W3C COGA](https://www.w3.org/TR/coga-usable/) 與 [Google](https://developers.google.com/style/tone) 支持用字面、具體的語言並避免不必要的譬喻，但沒有數量門檻。已改成「只在能承擔解釋功能時用」 |

另外兩條（需要判斷才附理由、校準語言）與 Google 的 procedures 與 tone 指引同向，未做限縮。
