# 設計決策與證據狀態

本檔記錄 `SKILL.md` 各條規則的**正當性來源**：哪些是本 skill 的設計決策、哪些從外部依據推導、哪些查過但不採用。

四區依「可動範圍」排序：**設計決策**（不可因外部依據變動而改）→ **混合型決策**（行為目標不可動、實作細節可調）→ **外部依據**（可依新證據修改）→ **已否決的主張**（不得因為在寫作圈流行就加回）。文末另有平台渲染細節與出處。

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
- **不變條件**：不使用中國用語；技術名詞保留英文不硬翻。
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

## 混合型決策

行為目標是本地採納的設計決策，外部資料只是佐證。**行為目標不可因外部依據變動而改；實作細節（數字、門檻）可調。**

| 編號 | 行為目標（不可動） | 可調部分 | 佐證 |
| --- | --- | --- | --- |
| WS-M01 | 不可為了短而刪掉理解所需的內容 | 具體的重讀觸發器怎麼寫 | plain language 系原則；W3C COGA 4.4.9、4.4.12 |
| WS-M02 | 「一句一事」限制的是主張數量，不是字數 | 判斷主張數量的提示 | 同上 |
| WS-M03 | 說明型條列每項自我完整，不逼讀者回查前文 | 例外情境 | COGA「不依賴記憶」目標 |
| WS-M04 | 先認定讀者，再決定機制要解釋到多深 | 讀者分類方式 | plain language「write for your audience」 |
| WS-M05 | 縮寫與代號首次出現附意義 | 豁免清單 | Google／Microsoft 縮寫規範 |
| WS-M06 | 跨文件引用要說明目前狀態，不只丟連結 | 狀態聲明的格式 | W3C「Status of This Document」慣例 |

這批來自實際文件的讀者回饋，使用者已採納修正。**注意**：採納「不可為了短而刪內容」不等於凍結所有相關數字——20 字、40 字這類實作數字不在保護範圍。

## 外部依據（可依新證據修改）

以下規則的正當性來自外部規範，證據變動就跟著調整：

| 規則 | 來源 | 適用範圍與注意事項 |
| --- | --- | --- |
| 每項 3 個以上屬性要對照就用表格 | [Google Style Guide: Tables](https://developers.google.com/style/tables) | 判準看屬性數不看項目數。本 skill 另加輔具、窄螢幕、儲存格過長三個例外，屬本地加註，不是原始來源的立場 |
| 清單 2–7 項 | [Microsoft Style Guide: Lists](https://learn.microsoft.com/en-us/style-guide/scannable-content/lists) | 官方寫的是建議值。其常被連結的 Miller 7±2 在認知科學界已被視為過度簡化，不要拿來當科學依據 |
| 只有 1~2 列不要做表格 | [Australian Style Manual: Tables](https://www.stylemanual.gov.au/structuring-content/tables) | 「表頭比內容重」是本地補充的理由，原文沒有 |
| 名詞連用三個以上就難讀 | [plainlanguage.gov: Avoid noun strings](https://www.plainlanguage.gov/guidelines/words/avoid-noun-strings/) | 門檻確為 3 |
| 斜線不可分隔替代選項、`&` 不可代 and | [Google: Slashes](https://developers.google.com/style/slashes)、[Word list](https://developers.google.com/style/word-list) | `&` 規則對 UI 元件、表頭、程式碼有例外 |
| 術語處理階梯（能換就換 → 保留＋首次說明 → 大型文件才建 glossary） | [Google: Jargon](https://developers.google.com/style/jargon)、[Microsoft: Use technical terms carefully](https://learn.microsoft.com/en-us/style-guide/word-choice/use-technical-terms-carefully)、[GOV.UK Technical A–Z](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/style-guides/technical-a-to-z/) | 四份都反對把必要術語砍光。Google 明確把 searchability 列為保留術語的正當理由 |
| 事件報告聚焦系統不聚焦個人，action item 要有 owner | [Google SRE Book: Postmortem Culture](https://sre.google/sre-book/postmortem-culture/) | 社群有「blame-aware」的修正意見，認為純 blameless 不符合人的實際反應 |
| 標點規範 | 教育部《重訂標點符號手冊》修訂版（2009） | 台灣現行的官方標點規範。不採 GB/T 15834——兩岸的分號定義、引號、標點位置有落差 |
| 摺疊區塊的使用時機 | [GitHub Docs: Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections) | 平台差異見下節 |
| 連結節制 | NN/g「A Link is a Promise」、[Google: Cross-references](https://developers.google.com/style/cross-references) | Google 現行立場是把連結放在最有用的位置；長頁面、多入口時可以重複。正文的「預設只連首次」已寫入這個例外 |
| 一段一概念、不設固定句數 | [Google: Paragraph structure](https://developers.google.com/style/paragraph-structure) | 現行立場是一句或超過六句都可能合理。正文據此改用「一段一個推論單位」的可觀測判準 |
| 認知可及性 | [W3C COGA: Making Content Usable](https://www.w3.org/TR/coga-usable/design_guide.html) 4.4.1、4.4.3、4.4.5、4.4.8、4.4.9、4.4.12 | 屬補充指引，不是 WCAG 強制條款 |

## 已否決的主張

查過但**不採用**，且**不得因為在寫作圈流行就重新加回**。加回前請先讀「為什麼」欄。

| 主張 | 判定 | 為什麼不用 |
| --- | --- | --- |
| 「79% 讀者掃讀而非逐字讀」 | 已否決當作依據 | 出自 1997 年的 web 瀏覽研究，NN/g [2008 年已改用](https://www.nngroup.com/articles/how-little-do-users-read/)「平均只讀 20-28% 字數」的框架。兩組數字都是 web 行為，不能外推到工作文件。掃讀預設改由 WS-D01 支撐，不需要比例數字 |
| 「GOV.UK 規定段落上限 5 句」 | 查無此出處 | GOV.UK 的實際規則是句長不超過 25 字。唯一寫死段落句數的是英國統計局自家 service manual，且是 4 句 |
| 任何固定的段落句數上限 | 不採用 | 沒有可靠來源支持單一數字，且會製造「為了符合形式而過度壓縮」的問題。改用「一段一個推論單位」的可觀測判準 |
| 「中文一句 20 字內最佳、40 字是上限」 | 查無來源 | 只找得到零星部落格的「15-25 字」建議，無學術或官方來源。改用可觀測的重讀觸發器取代字數門檻 |
| 「破折號堆疊是 AI 生成特徵」 | 降級為弱訊號 | 屬流行認知，會誤傷本來就慣用破折號的作者。破折號限量的理由改用可讀性（過量或關係不明會妨礙理解） |
| 「BLUF、inverted pyramid、Minto、GOV.UK 四個體系同向」 | 引用有誤 | HBR 2016 原文只提 BLUF 與 inverted pyramid 相似，沒提 Minto。Minto 的核心是歸納／演繹論證階層，跟純重要性排序不同 |
| 用 Diátaxis 當「讀者範圍」的分層依據 | 接錯軸 | Diátaxis 分的是讀者當下的需求情境（學習／解決問題／查閱／理解），不是讀者身份或知識程度 |
| Jansen (2014) 的 bullet 研究可當無條件通則 | 過度簡化 | 原文是五個分研究的有條件結果：三個發現 bullet 有助清單記憶（項目異質時效果減弱）、兩個發現傷及周邊段落記憶，但讀者對文章整體評價反而更好 |
| Bionic Reading 式加粗（每個字前半段加粗） | 不採用 | 2024-2025 多篇對照研究（含眼動追蹤）未發現速度或理解上的效益，例如 [Acta Psychologica 2024](https://www.sciencedirect.com/science/article/pii/S0001691824001811)，部分研究另觀察到負面效果。泛稱「標記關鍵字有助聚焦」則屬社群主流、無直接對照實驗 |
| 用 WCAG 2.2 SC 3.1.5 Reading Level 當硬門檻 | 不採用 | 它是 web 的 AAA 條款，對一般文件過嚴；COGA 的條目對本 skill 更直接 |
| 讀者可讀性分數（Flesch-Kincaid 之類）當通過標準 | 不採用 | 屬工具與顧問慣例，非 plainlanguage.gov／GOV.UK 的規定；量化門檻容易變成新的形式主義 |

## 平台與渲染細節

`<details>/<summary>` 摺疊的相容性：

- CodiMD／HackMD、GitHub 與多數 IDE 預覽都支援。
- **Notion**：貼上或匯入 Markdown 時會移除標籤，內容可能整段消失，不會變成 toggle。其 API 另有支援 details/summary，但貼上、匯入、API 是三條不同通路，不能互相外推。確定要貼到 Notion 的文件先展開，改用「存查材料後置＋文末附錄」。
- **Firefox／Safari** 的頁內搜尋找不到摺疊內容。
- 列印預設不含摺疊內容。

## 其他出處

- NN/g「Inverted Pyramid」「How Users Read on the Web」「How Little Do Users Read?」；[Jansen (2014), *Information Design Journal* 21(2)](https://www.jbe-platform.com/content/journals/1569979x/21/2)
- BLUF（美軍慣例，HBR 2016 推廣）
- Axios Smart Brevity（商業 update 的掃讀體）；批評見 Columbia Journalism Review 與 New Republic：複雜議題會被扁平化、脈絡流失
- Federal Plain Language Guidelines（資料進表格，內文只留一兩項）
- Diátaxis（文件分型，屬資訊架構層）
- 關於 LLM 寫作的兩項實證，用來支撐「掃讀但不失真」：LLM 摘要出現廣泛概化的比率高於人類科學摘要（Peters & Chin-Yee, 2025, *Royal Society Open Science*，4,900 份摘要、10 個模型，odds ratio 4.85，[DOI](https://doi.org/10.1098/rsos.241776)；適用範圍限科學與醫學摘要，不外推為所有文件的固定風險率）；即使 prompt 指定目標讀者，模型輸出的可讀性範圍仍難調動（[arXiv 2312.02065](https://arxiv.org/abs/2312.02065)）
