# 設計決策與證據狀態

本檔記錄 `SKILL.md` 各條規則的**正當性來源**：哪些是本 skill 的設計決策、哪些從外部依據推導、哪些查過但不採用。本 skill 的目標是好讀，不失真是底線（WS-D10），覆核任何規則都以此為準。

## 目錄

依「可動範圍」由嚴到寬排序：

1. **覆核這個 skill 時的規則**——四類正當性來源各自能改什麼、重開條件。
2. **設計決策 WS-D01～D10**：不可因外部依據變動而改。
3. **混合型決策 WS-M01～M10**（WS-M10 已撤銷）：行為目標不可動，實作細節（數字、門檻）可調。
4. **4.0.0 新增規則的正當性分類**：每條新規則屬於來源直接要求、移用推導或待驗證的設計選擇。
5. **外部依據**：可依新證據修改。
6. **已否決的主張**：不得因為在寫作圈流行就加回。
7. **平台與渲染細節**：收合、畫圖平台的相容性與實測紀錄。
8. **句子層細則的證據身分**：`examples.md`「句子的寫法」那六條的查證結果。

同目錄另有 `examples.md`（語氣變體、正反例全集、AI 常犯問題的判斷細節）、`doc-types.md`（各類文件的骨架）、`diagrams.md`（畫圖的平台與語法）與 `taiwan-terms.md`（中國用語對照表）。

## 覆核這個 skill 時的規則

**先讀完本檔再提出任何刪改。** 規則的正當性來源不同，可動的範圍就不同：

| 正當性來源 | 外部依據失效時可以做什麼 | 不可以做什麼 |
| --- | --- | --- |
| 設計決策 | 修正引用、更新理由、提出重開建議 | 改掉或降級「不變條件」 |
| 混合型（本地採納＋外部旁證） | 同上，另可調整實作細節（數字、門檻、措辭） | 改掉行為目標本身 |
| 外部依據推導 | 依新證據修改或刪除 | 無額外的決策保護，但仍須符合目標與底線（WS-D10）、既有設計決策與正確性要求 |
| 來源不明 | 先查 git log、既有紀錄或詢問維護者 | 預設當成外部推導規則直接刪改 |

**依據站不住不等於規則要改。** 設計決策的正當性來自使用需求，引用只是佐證；引用失效的正確處置是撤掉引用，規則不動。

重開條件（任一成立即可重新討論，不必等全部滿足）：

- 維護者明確表示需求或主要使用情境已改變。
- 這個決策造成正確性、安全或無障礙問題——一個可信案例即可重開。
- 在兩份不同的實際產出中，重複造成相同的理解或使用失敗。
- skill 的目標讀者、觸發範圍或定位改變。
- 替代方案經新舊產出比較，能保留原目標並明顯改善結果。

外部 guide 更新、引用失效、reviewer 偏好不同，可以觸發證據覆核，但不能自動翻轉設計決策；有疑似衝突就提重開建議交維護者裁決。

**覆核與審查同時問兩題，同等權重**：哪裡可能失真？哪裡讓讀者更累？只找失真風險的審查，會讓規則一路往「多加一條保護」堆疊，3.x 就是這樣演進的（見 WS-D10）。

本檔記錄的是**目前有效的約束**，不是修訂歷史——歷史交給 git log。

## 設計決策

### WS-D01：預設採掃讀型

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求。
- **不變條件**：未命中明確例外時，產出必須提供可掃讀路徑。
- **可調部分**：標題命名、條列層數、表格與條列的選擇、句長提示、掃讀的檢查方法、因果推導的呈現形式。
- **理由**：主要使用情境幾乎都需要快速且精準地掌握資訊；未明示時，模型常輸出不利掃讀的長段落。
- **4.0.0 的調整（只動可調部分）**：
  - 撤掉「因果推導先改寫成結論一句加理由條列，改寫會斷邏輯才留段落」這條預設，改成依內容選形式，因果推導、權衡與連續推理用短段落。理由：[Jansen](https://research-portal.uu.nl/en/publications/how-bulleted-lists-and-enumerations-in-formatted-paragraphs-affec/) 的條列研究是有條件的結果（改善項目記憶、傷害周邊文字記憶），本檔早已否決把它當無條件通則，本文卻仍預設條列，前後不一致。把因果鏈拆成條列也會砍掉連接詞，讀者看不出哪件導致哪件、哪一段是推論。
  - 掃讀的檢查方法改成可觀察判準：只讀標題與每段首句，就取得當前任務需要的資訊而且不誤解。依用途分，分析與決策型給判斷、操作型給動作、查閱型給定義或查找入口，不要求每段硬加結論。段落長度由最長區塊抽查守住。
  - 必守的仍是「有可掃讀且不失真的路徑」，檢查方法可以替換。撤掉的是一條會改變產出的規則，所以版號升主版號。
- **與外部依據的關係**：外部研究可以改善做法，但不決定是否採用這個預設。原本引用的「79% 讀者掃讀」已撤除（理由見「已否決的主張」），撤除不影響本決策。
- **日期**：2026-07-16 定，2026-07-27 再確認。

### WS-D02：文體判準跟著讀者的使用方式走

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求。
- **不變條件**：反覆查閱、跨文件比對的文件一律掃讀型（報告、決策紀錄、狀態檔、規格、稽核）；論述型只限一次性完整閱讀的說服內容。
- **可調部分**：哪些文件類型歸哪一邊的清單。
- **理由**：用「內容怎麼產生」分類會把需要反覆查閱的文件寫成長篇論述，讀者每次回來都要重讀。
- **與 4.0.0 的關係**：因果推導改用短段落後，反覆查閱的文件仍是掃讀型。短段落的首句給判斷，只讀標題與首句的掃讀路徑照樣成立，不因此改成論述型。
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
- **落實**：交付前驗證的讀者複述、「哪裡讓讀者更累」這一問，以及衝突裁決表最後一列。

### WS-D05：研究型產出的讀者知識預設

- **狀態**：有效。
- **正當性來源**：本 skill 的設計需求，來自實際失敗——研究陌生領域後產出的報告滿篇該領域術語，委託研究的人讀不懂。
- **不變條件**：研究與調查型產出的預設讀者不熟該領域。陌生術語不得阻礙理解，同時要保留可供搜尋與跟人討論的正式名稱。
- **可調部分**：處理階梯的步驟、白話說明的寫法、建 glossary 的門檻。
- **理由**：委託研究這件事本身就是不熟的訊號。模型讀完大量來源文獻後會沿用來源的用語，這個傾向要靠規則抵銷，不能靠自覺。
- **與外部依據的關係**：四份 style guide 的術語處理階梯是做法來源與佐證，但這個結果要求不因外部 guide 更新而刪除。
- **與「依題目熟悉度決定解釋多深」的關係**（4.0.0 新增，外部推導自 Kalyuga 等 2003 的專家反轉效應）：兩者並存。熟悉度是判斷依據，本條是研究與調查型產出的預設值：沒有證據顯示讀者熟悉這個題目時，一律當不熟。
- **日期**：2026-07-27。

### WS-D06：可見主線優先服務當前任務

- **狀態**：有效。
- **正當性來源**：實際使用回饋與本 skill 的設計需求。不是從 GitHub 的 `<details>` 文件推導——那份文件只支撐收合怎麼用，撐不起四類分流、處理順序與收合的條件與禁令。
- **不變條件**：可見主線優先服務讀者的當前任務；背景、例外與參考資料不得擋在必要判斷與最短成功路徑之前。
- **可調部分**：四類分流的名稱與邊界、收合的條件、最長區塊抽查的數量。
- **第八輪的調整（只動可調部分）**：收合從「三個條件同時成立才可收合」改成查證細節與決策背景在支援收合的平台預設收合，禁令保留：會改變判斷或行動的內容不收合。不變條件照舊，背景與參考資料仍不擋在必要判斷之前，收合是讓它們不擋路的呈現方式。
- **理由**：實跑一份導入教學時，局部規則全數合格（每項自我完整、每段一個推論單位、術語都有解釋），讀者仍回饋「字很多很難讀」。原因是內部機制與詞彙表擋在第一次成功之前——第一次實際操作到第 147 行才出現。規範原本只檢查每一段寫得好不好，沒有檢查這段現在該不該出現。
- **外部依據的關係**：雙模型各自跑過 consensus 查證，結論一致——底層原則有支持（Diátaxis 的 tutorial 要先給可見成果並把 explanation 移出、DITA 的 task／concept／reference 分型、GOV.UK 要求內容回應實際使用者需求、W3C 要求非主要目的的內容與主線分離），但**四類分流本身沒有任何框架採用相同切法**，它混合了「內容用途」與「在當前流程的位置」兩條軸線。所以這是有理據的本地決策，不能宣稱它是 Diátaxis 或 DITA 的分類法。
- **邊界**：「最短成功路徑」不等於無條件追求步驟最少。真正必要的 prerequisite 仍應放在操作之前（DITA、Write the Docs 立場），Diátaxis 的 tutorial 也是學習經驗而非最快完成任務。
- **日期**：2026-07-27。

### WS-D07：人稱跟著文件流通範圍走

- **狀態**：有效。
- **正當性來源**：維護者 2026-08-08 定案的設計決策，來自實際轉出文件的定型經驗。
- **不變條件**：點對點、明確收發者的訊息與信件保留人稱；預期被轉發、脫離對話脈絡流通的文件與簡報材料用無人稱事實句；owner、責任、決策者會影響行動時人名照寫（無人稱管文法人稱，不管責任歸屬）。
- **可調部分**：無人稱句型的示例、「預期被轉發」的判斷提示。
- **理由**：「我／你」在第三者手上指涉錯亂——無人稱的依據是轉發時的功能需求，不是任何寫作傳統的權威要求。
- **與外部依據的關係**：兩側各有佐證，強度不同。美軍 AR 25-50《Preparing and Managing Correspondence》第 1-39.b.(6) 段建議 correspondence 用 I、you、we 當句子主詞（支持「點對點保留人稱」側；查證時 .mil 官方網域連線失敗，經第三方鏡射 armywriter.com 以修訂日期交叉核對，有方法折扣）。Amazon 6-pager 文件刻意不具名、範本句無人稱（出自前員工文章，屬社群來源非官方；只能證明匿名慣例本身，不能證明動機是轉發——相鄰案例，不當作轉發判準的正向證據）。**引用紀律：不得宣稱無人稱繼承自 BLUF 或 briefing note 傳統**（理由見「已否決的主張」）。
- **日期**：2026-08-08。

### WS-D08：轉出工作檔前必跑外流檢查

- **狀態**：有效（2026-10-17 依重開條件第一條重開後改寫）。
- **正當性來源**：本 skill 的設計需求，來自實際失敗（2026-08-08）：一份工作檔的附錄放著給對方本人的訊息草稿，整理給對方的版本差點把它原樣傳出去。
- **不變條件**：把自己的工作檔（含 AI 筆記、路徑、內部代號、給對方的草稿）轉給別人前，必跑外流檢查，清單至少含收件人無權取得的內容（個資、機密、憑證與 secret、內部識別）、內部狀態行、內部連結、給對方本人的草稿、AI 協作痕跡、frontmatter。
- **可調部分**：檢查清單的項目增補與措辭、「工作檔」的認定提示。
- **重開紀錄（2026-10-17）**：原本的不變條件是「內部完整版是唯一事實來源，分享版是裁切產物，轉分享版必跑裁切流程與外流檢查」。維護者實際使用時問「我搞不懂為什麼還有分享版跟什麼版」，聽完由來後裁決：預設一開始就寫給讀者的那一份，不另產兩個檔，檔名不再出現「分享版」字樣，只有轉出工作檔時才跑一次外流檢查。原因判斷：兩份並存的要求被執行成每次都產兩個檔，讀者分不清哪份算數，維護成本也加倍，而當初的失敗真正要防的是工作檔裡的東西外流，外流檢查就守得住。所以撤銷「兩份並存、裁切產物」與六步裁切流程，保留外流檢查。
- **日期**：2026-08-08 定，2026-10-17 重開改寫。

### WS-D09：每份文件開頭有受硬上限的同步層

- **狀態**：有效。
- **正當性來源**：維護者 2026-09-02 定案的設計決策，來自實際回饋——2.x 各版改善了單份文件內部的寫法，總量卻沒降（兩次行為對照新版都比舊版長），使用者仍覺得「很多字、很長」。診斷：既有的減法規則（刪背景、移細節、略過不適用的節）都是判斷題、沒有門檻，沒有任何規則對可見層設上限，拉扯時一律輸給「不失真」側。
- **不變條件**：文件開頭（標題之後、第一個 `##` 之前）是同步層，只放結論或現況、已決定的事、要讀者做的事、哪裡可以停（四項依文件需要選用）；同步層有硬上限；放不進去的內容一律落到展開層（後置小節、附錄、拆檔），不得因此刪除。同步層不得出現本文件首次定義的術語。
- **可調部分**：待決事項多時「讓讀者知道全部範圍並能直接跳到清單」的寫法（4.0.0 新增，來自評估觀察：一份產出開頭只提兩項待決，完整六項到後段才出現）；上限數字（目前規則寫 5 個主張、hook 量 400 字元，後者約等於一分鐘的中文閱讀量，只是換算說明。這是維護者採用的**實驗初始值**，不是外部共識，待用實際文件 A/B 校準：首次拿到可執行結論的時間、能否安全停讀、有沒有漏掉關鍵但書）、四項的名稱與順序、展開層的排序細則。
- **與第六、七輪開頭寫法的關係**：第七輪的開頭寫法是前兩句交代發生什麼、寫給誰、讀完要做什麼，再接要決定的事或結論。其中「寫給誰」不在不變條件列的四項裡，目前當成「要讀者做的事」的對象說明處理。維護者若認為它是新的一項，要依重開條件第一條改不變條件，不能由覆核者自行擴充。
- **與 WS-M01 的關係**：不衝突。WS-M01 保護的是「不可刪」，本條做的是「移」。**與「已否決的主張：任何固定的段落句數上限」的差別**：被否決的是約束句段內部形式的數字（會誘導砍限定語湊字數）；本條約束的是可見層的主張總量並強制指定去處，限定語跟著主張走、算同一個主張。覆核時不得拿那條否決來刪本條。
- **與 WS-M09 的關係**：同步層是給人讀的部分的開頭。文件分成給人讀與查證用兩部分時，本條的位置、上限與術語限制照舊適用。本條管開頭的位置與可見量，WS-M09 的準確性要求涵蓋整個給人讀的部分（同步層也算在內），寫法建議主要用在同步層之後的主線。
- **證據身分（全部是類比或本地推論，沒有任何來源直接支持同步層架構或 5／400 這組數字）**：[AR 25-50](https://armypubs.army.mil/epubs/DR_pubs/DR_a/ARN42124-AR_25-50-007-WEB-13.pdf) §1-39b(7) 規範的是美軍公文「多數一頁、附加資訊走 enclosure」，只支持「受限主文加附件」這個形狀；[Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)「Written deliverable length」只支持明確校準長度並刪除填充，不給數字；[LIFEBench](https://arxiv.org/abs/2505.16234) 只顯示短長度指示比長的容易遵循，支持把數字放在小的同步層。Basecamp、GitLab、Stripe 的寫作規範查無字數上限。數字是本地決策。
- **失敗模式與執行層**：硬上限可能 Goodhart——砍限定語、或用多層子句把主張塞進一句以通過字數檢查；防守靠衝突裁決表「移走整個主張、不拆限定語」與驗收列的明文禁止，沒有研究量過「為達標砍掉的是填充還是實質」。2026-08-11 的對照只直接觀測到符號與標點：靠 prompt 守不穩、進 hook 才穩；同步層長度能否靠 prompt 守住仍待 A/B。同步層字元數與符號串接由 `scripts/check-doc-shape-hook.sh` 檢查，只警示、不阻擋、不截斷；語意層的判斷（哪個主張可以移、哪個但書必須留）留在 prompt。
- **日期**：2026-09-02。

### WS-D10：目標是好讀，不失真是底線

- **狀態**：有效。
- **正當性來源**：維護者 2026-10-11 的明確需求（重開條件第一條）：這個 skill 的目的就是讓文件好讀。
- **不變條件**：本 skill 的目標是讓讀者省力地讀懂並用上文件，也就是找得到、看得懂、用得上。不失真是底線而不是目標，範圍限於會改變讀者判斷或行動的內容，也就是五種限制。底線以外，規則衝突時好讀勝。審查與驗收同時問「哪裡可能失真」與「哪裡讓讀者更累」，兩者同等權重。
- **可調部分**：好讀的量法（機械觀察值、讀者吃力自評、找到要決定的事所花的時間）；衝突裁決表各列的措辭；五種限制的分類與措辭（同 WS-M09）。
- **理由**：3.x 一路以「出錯就加保護」演進，舊衝突裁決表七列有六列判準確那側勝，好讀被擠成次要。4.0.0 的重構研究與審查也重演同一傾向：審查只找失真風險，不找閱讀負擔。寫成設計決策，是為了避免下一輪覆核再把天平推回去。
- **與外部依據的關係**：[ISO 24495-1](https://cdn.standards.iteh.ai/samples/78907/d194fac21d6a45f38bfcfec9657f7498/ISO-24495-1-2023.pdf) 對白話寫作的四項原則（讀者拿到需要的、找得到、看得懂、用得上）是好讀的操作定義，屬佐證。底線的五種限制來自 WS-M09 的跨來源整理。外部依據變動不改本條。
- **與其他條目的關係**：WS-M01（不為短刪理解所需）與本條同向，理解需要的內容本來就屬於好讀。WS-D09 與 WS-M09 守的是底線，本條不放寬它們的不變條件，只決定底線以外的衝突怎麼判。
- **日期**：2026-10-11。

## 混合型決策

行為目標是本地採納的設計決策，外部資料只是佐證。**行為目標不可因外部依據變動而改；實作細節（數字、門檻）可調。**

| 編號 | 行為目標（不可動） | 可調部分 | 佐證 |
| --- | --- | --- | --- |
| WS-M01 | 不可為了短而刪掉理解所需的內容。**同步層預算（WS-D09）與此不衝突：它做的是「移到展開層」，不是刪。分兩部分（WS-M09）也是移：只有不影響理解與判斷的細節移到查證用的部分** | 具體的重讀觸發器怎麼寫 | plain language 系原則；W3C COGA 4.4.9、4.4.12；兩篇 LLM 研究（細節見表後） |
| WS-M02 | 「一句一事」限制的是主張數量，不是字數 | 判斷主張數量的提示 | 同上 |
| WS-M03 | 說明型條列每項自我完整，不逼讀者回查前文 | 例外情境 | COGA「不依賴記憶」目標 |
| WS-M04 | 先認定讀者，再決定機制要解釋到多深 | 讀者分類方式；4.0.0 起與「依讀者對題目的熟悉度」合併寫在 `SKILL.md` 第 1 節 | plain language「write for your audience」 |
| WS-M05 | 縮寫與代號首次出現附意義 | 豁免清單 | Google／Microsoft 縮寫規範 |
| WS-M06 | 跨文件引用要說明目前狀態，不只丟連結 | 狀態聲明的格式 | W3C「Status of This Document」慣例（**類比**，不是直接證據——該慣例規範的是 W3C 規格文件，不是一般跨文件引用） |
| WS-M07 | 長篇報告要讓不同閱讀深度的人都拿到核心資訊：執行摘要能脫離全文獨立閱讀，非必要的查證材料不擋在正文 | 是否設附錄、各層名稱、摘要長度；4.0.0 起寫在 `SKILL.md` 第 2 節，`examples.md` 重複的段落已刪 | 現行工程報告慣例（[IEEE: Write Effective Reports](https://procomm.ieee.org/communication-resources-for-engineers/written-reports/write-effective-reports/)）區分 executive summary、body、appendices，是最直接的支持；適用邊界見表後 |
| WS-M08 | 轉給主管或其他團隊的文件，詞彙以與對方共同場合出現過的詞為界（第九輪起不再有「分享版」，適用對象改寫成這樣，行為目標不變） | 「共同場合」的認定方式、白名單外術語的處置 | plain language 三方官方一致的「write for your audience」（[digital.gov](https://digital.gov/guides/plain-language/principles/write-for-reader)、[GOV.UK](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)、EU《How to write clearly》）；「以共同場合出現過的詞為界」的操作法是本地強化，官方原文沒有這個界線 |
| WS-M09 | 讀者需要不同閱讀深度時分成給人讀與查證用兩部分：給人讀的部分能單獨正確使用，會改變理解的限制緊貼主張留在這部分；查證用的部分精確可回查；兩部分不矛盾 | 五種限制的分類與措辭、五種限制的標法、給人讀的部分的寫法、觸發分兩部分的文件類型、複述驗收的執行方式 | Cochrane 白話摘要指南、EU lay summary 指南、英國政府統計指南、digital.gov 複述測試（細節見表後「WS-M09 的完整紀錄」） |
| WS-M10（已撤銷） | 分成兩部分時，給人讀的部分有總量預算，超過就把證據細節移到查證用的部分；每個結論在上方只帶一句證據摘要與它的限制，並指向下方對應節；會改變判斷的限制不因預算移走 | 預算數字（目前約 1,500 字）、量測方式、適用的文件類型 | 報告摘要約一頁、約全文 10% 的業界慣例；AR 25-50「多數一頁、附加資訊走附件」（細節見表後「WS-M10 的完整紀錄」） |

這批來自實際文件的讀者回饋，使用者已採納修正。**注意**：採納「不可為了短而刪內容」不等於凍結所有相關數字——20 字、40 字這類實作數字不在保護範圍。

佐證欄的查證細節（儲存格只留摘要，細節放這裡）：

- **WS-M01 的兩篇 LLM 研究**：LLM 摘要出現廣泛概化的比率高於人類科學摘要（[Peters & Chin-Yee, 2025](https://doi.org/10.1098/rsos.241776)，4,900 份摘要、10 個模型，odds ratio 4.85；限科學與醫學摘要，不外推為所有文件的固定風險率）；即使 prompt 指定目標讀者，模型輸出的可讀性範圍仍難調動（[arXiv 2312.02065](https://arxiv.org/abs/2312.02065)）。
- **WS-M07 的適用邊界**：**ISO 5966 已於 2000 年撤銷**，只能當歷史來源，不可當現行標準引用。IEEE 只說執行摘要最長約可到全文 10%，「5–10%」是誤植，本 skill 不寫死比例。[Minto](https://www.barbaraminto.com/) 支持的是「主要結論在上、支持論點在下，上層概括其下層論點」的**論點階層**，不直接主張「同一份文件分層服務不同角色」，兩者不要混為一談。PNAS 的三層規範（Significance Statement 最多 120 個英文單字，讀者是受過大學科學教育、但不在該專業領域的科學工作者；Abstract 給同行；再來是全文）是少數有明文字數的案例，可參考不可外推（[PNAS 投稿規範](https://www.pnas.org/author-center/submitting-your-manuscript)）。WS-M09 把「摘要能獨立閱讀」延伸到要讓人複述、轉述的說明，另加五種限制的逐項檢查與複述驗收。

### WS-M09 的完整紀錄

- **狀態**：有效。
- **歸類為混合型的理由**：假如外部依據全部失效，維護者仍然要「讀者需要不同閱讀深度時分兩部分、給人讀的部分能單獨正確使用」，所以行為目標是本地採納的決策（WS-D04 讀者回饋優先的延伸）。但五種限制的清單是跨來源整理出來的，問題式標題、照因果順序一步一條、每條一兩句是本地偏好，都應該隨證據與使用回饋調整，不能寫成不變條件，所以不是純設計決策。
- **行為目標（不可動）**：見上表。補充兩點：只讀給人讀的部分的人要能正確複述與判斷；兩部分不要求逐句對應，允許合併與重排，但每個主張都能對回查證用的部分。只有不影響理解與判斷的細節可以後置，必要的分母、比較基準、不確定性與會改變方法選擇的結果不在可後置範圍。
- **可調部分**：五種限制的分類與措辭（清單本身只寫在 `SKILL.md` 一處）；五種限制的標法（4.0.0 起：每個主張都檢查，主要判斷就近標，同一小節內條件與強度完全相同的標示可共用一次）；給人讀的部分的寫法；哪些文件類型要分兩部分；複述驗收的題目與人數；兩部分的分隔形式（分隔線、講者備註、附錄）。
- **正當性來源**：維護者 2026-10-04 的回饋。一份給人上台前讀的說明照現行規則寫，補進審查要求的十三處限定語後，同一句塞進多個條件、每條三四件事，讀者回饋「太難讀」。改寫成「標題寫讀者的問題、照因果順序一步一條、粗體點出每步、每條一兩句、只留會改變理解的限制、精確細節移到分隔線下」後，維護者說這比本 skill 定義的掃讀體更像他想像的掃讀體。符合重開條件第一條（維護者明確表示需求已改變）。
- **外部旁證**（兩個不同模型家族各自獨立查證，結論同向，2026-10 查）：
  - 分層是公認做法：[W3C：Provide Summary of Long Documents and Media](https://www.w3.org/WAI/WCAG2/supplemental/patterns/o3p08-summary-provided/)（認知無障礙補充指引，非 WCAG 強制條款）、[Cochrane Plain language summary 指南](https://www.cochrane.org/authors/handbooks-and-manuals/handbook/current/guidance-writing-cochrane-plain-language-summary.pdf)、[EU：Summaries of Clinical Trial Results for Laypersons](https://health.ec.europa.eu/system/files/2020-02/2017_01_26_summaries_of_ct_results_for_laypersons_0.pdf)。EU 指南允許合理取整數，但不能讓一般讀者摘要與技術摘要看起來不一致，這是衝突裁決表「白話 vs 忠於來源」補上取整數條件的依據。
  - 重要限制不能整批移走：Cochrane 指南 §2.2、§2.5、§3 要求主要訊息保留證據可靠程度、適用對象、重要差異與危害，並提醒讀者可能只讀主要訊息。§2.6 直接要求交代證據的主要限制，§3 也要求白話摘要不得加入完整版沒有的資訊。[英國政府統計指南：Communicating quality, uncertainty and change](https://analysisfunction.civilservice.gov.uk/policy-store/communicating-quality-uncertainty-and-change/) 要求關鍵限制放在它限制的主張旁，不能藏在附錄或註腳，詳細方法可另外提供（2018 版，標示待更新）。[NICE NG197 §1.4](https://www.nice.org.uk/guidance/ng197/chapter/recommendations) 與 [IPCC 不確定性指引](https://www.ipcc.ch/site/assets/uploads/2017/08/AR5_Uncertainty_Guidance_Note.pdf) 也要求交代重要的不確定性。
  - **五種限制是跨來源整理的判準**，不是任何單一標準的原文清單。
  - 數字取捨：[CDC Clear Communication Index User Guide](https://www.cdc.gov/ccindex/pdf/clear-communication-user-guide.pdf) item 15 要求選擇支撐主要訊息的數字。所以本條寫「支撐主要訊息所需的那幾個」，不寫「好記的、講得出口的」，後者查無支持。
  - 複述驗收：[digital.gov：Paraphrase testing](https://digital.gov/guides/plain-language/test/paraphrase-testing/)（請讀者用自己的話解釋、先記錄不糾正、依誤解改文件，建議 6 到 9 位受試者）、[AHRQ：Use the Teach-Back Method，Tool 5](https://www.ahrq.gov/health-literacy/improve/precautions/tool5.html)。6 到 9 位是文件測試的建議人數，不是所有用途的門檻。teach-back 用來確認當事人本人的理解，所以一位目標讀者（例如要上台的講者）的複述能確認他本人，不能推論其他讀者也懂。
  - 結論先行與因果順序可以並用：[digital.gov：Organize the information](https://digital.gov/guides/plain-language/principles/organize) 同時支持主要訊息先行與流程依發生順序呈現。
- **查無直接證據的部分**：
  - 「照因果順序一步一條」「每條一兩句」普遍優於「結論＋理由條列」：查無控制相同內容的直接比較。只有局部證據，例如先因後果能加快辨識與原因相關的詞（[Discourse Processes, 2011](https://doi.org/10.1080/0163853X.2011.607952)，測的是局部反應時間）。所以只寫成這類情境的建議做法。
  - 「複述講錯就代表限定語太少」：查無。講錯的原因可能是用詞、順序、數字形式或缺少背景。
  - 給一般讀者要保留多少不確定性：查無通用公式。分層本身會增加還是降低語言模型的過度概化：查無直接研究。
- **反例與相左證據**：
  - 敘事不一定較好：三個預註冊實驗、共 2,279 人，比較敘事與非敘事的誤訊息修正，沒有找到敘事優勢（[You don't have to tell a story!](https://link.springer.com/article/10.1186/s41235-020-00266-x)）。不是本條寫法的直接測試，但足以反對「照順序講一定較好」。
  - 加限制段未必足夠：300 名專家讀者的試驗中，摘要加入限制段後沒有顯著改變信心或效益判讀（[Impact of adding a limitations section to abstracts](https://ora.ox.ac.uk/objects/uuid%3Ae6c65e83-7e1f-4eba-8f9c-ec79c314c909)）。所以本條靠複述驗收抓理解錯誤，不靠堆限定語。
  - [ONS bulletins 寫作指南](https://service-manual.ons.gov.uk/content/content-types/bulletins) 要求主要重點不塞詳細定義與品質警告，但同一份指南要求分析裡留簡短警告、詳細說明後置，方向與本條相同。
  - 數字取捨沒有統一規則：[2022 年白話摘要系統性回顧](https://pmc.ncbi.nlm.nih.gov/articles/PMC9170105/) 發現各指南差異很大。
- **失敗模式**：
  - **讀者只讀給人讀的部分**：一項 36 人的小樣本研究中約 37% 表示想讀全文（[Cochrane 摘要研究](https://journals.sagepub.com/doi/10.1177/0141076814546710)），摘要措辭也能改變判斷（[SPIIN 隨機試驗](https://ascopubs.org/doi/abs/10.1200/jco.2014.56.7503)，300 名臨床讀者）。所以給人讀的部分漏掉的限制，查證用的部分補救不了。
  - **沒有清單時限制會漏**：只寫「留會讓人講錯的限制」要靠寫作者判斷。觸發本條的實例在改寫初稿時，原因未明的事被寫成已知原因，一個較小但未驗證的數字被略掉後改寫成「其他試法都沒有比較好」。這是把限制寫成五類清單的理由。
  - **語言模型從查證用的部分壓縮出給人讀的部分**：這正是 [Peters & Chin-Yee, 2025](https://doi.org/10.1098/rsos.241776) 量到過度概化的步驟，三種典型錯法是把有量化的主張改成通則、把過去的發現改成現在式、把描述改成行動建議。寫完要逐句對照這三類。
  - **形式建議被當成硬規定**：「每條一兩句」被當成上限會誘導砍限定語湊句數，等於回到已否決的「固定段落句數上限」。反過來，把五種限制當成每個主張都要補五句，又會回到原本塞滿限定語的寫法。防守是明寫一兩句是目標不是上限、五種限制是逐項檢查表、照順序講只用在需要解釋推導或流程的地方。
  - **兩部分漂移**：改一邊忘了另一邊。防守是「每個主張都能對回查證用的部分」這道檢查。
  - **複述驗收被誤用**：把一位讀者講對推論成其他讀者也懂、只附三題就當作驗收完成，或把「講得清楚」當成「來源正確」。沒取得回答時標「複述待驗」，複述只測理解。
- **與 WS-M01 的關係**：不衝突。不影響理解與判斷的細節移到查證用的部分是移，不是刪。逐項檢查後該留的限制不在可移範圍。
- **第六輪對寫法的調整（可調部分）**：維護者 2026-10-11 與 10-12 兩次盲讀後，標題改用讀者熟悉的書面短語，問題式標題不再是建議做法；確定程度不貼「已觀測、推論」標籤，只在會改變決定的地方用一句自然的話說。不變的是行為目標：會改變理解的限制仍緊貼主張留在給人讀的部分。
- **與 WS-D09 的關係**：同步層是給人讀的部分的開頭，位置、上限與術語限制不變。WS-D09 管開頭的位置與可見量，本條的準確性要求涵蓋整個給人讀的部分（同步層也算在內），寫法建議主要用在同步層之後的主線。
- **與 WS-D02、WS-M07 的關係**：WS-D02 列的反覆查閱文件（狀態檔、規格、決策紀錄、稽核）不分兩部分，維持現行掃讀規則。WS-M07 要求執行摘要能獨立閱讀，本條把它延伸到要讓人複述與轉述的說明。
- **日期**：2026-10-04。

### WS-M10 的完整紀錄

- **狀態**：已撤銷（2026-10-11，同日新增後撤銷）。保留紀錄供下次有人想加回固定預算時查。
- **撤銷理由**：
  - 維護者盲讀新舊兩版的決策報告，偏好篇幅較長、依序講清楚經過的那份，回饋是砍短的版本「跳躍、沒頭沒尾」。
  - 兩家各自查公認好文件的實例，沒有通用的一頁共識。Amazon 的敘事備忘錄雖有頁數上限，細節進附錄，而且 Bezos 批評條列化會切斷想法之間的關聯（[2017 股東信](https://www.aboutamazon.com/news/company-news/2017-letter-to-shareholders)）。
  - 改用不設固定篇幅、太長時依序處理：細節移後、刪重複、最後才刪事項，因果與轉折的連接句不刪。腳本的對應檢查改成預設不啟用（另一路處理）。
- **撤銷前的原始紀錄**（以下保留原文）：
- **歸類為混合型的理由**：行為目標是本地決策：WS-D09 用硬上限管開頭，同樣的問題在給人讀的部分重演，需要同一種解法。1,500 字這個數字與量測方式是實驗值，應隨實際文件校準，所以不是純設計決策。不併進 WS-D09，是因為 WS-D09 的不變條件只管開頭，延伸它等於改動受保護條目的範圍。
- **行為目標（不可動）**：給人讀的部分有總量預算，超過時只移只是佐證的細節，不移限制，也不把必要判斷移進標「不必讀」的部分。時間、筆數、錯誤碼依用途判斷：只是佐證就後移，界定適用期間、必要分母或操作分支的留在上方。每個結論在上方保留一句證據摘要與會改變判斷的限制，並指向下方對應節。開頭上限（WS-D09）與本條分開裁決：開頭放不下的整個主張移到上方後續小節，上方超過預算只能移佐證細節。
- **可調部分**：預算數字（目前約 1,500 字，約一頁 A4，是實驗初始值，跟 WS-D09 的 400 字元一樣待實際文件校準）、量測方式（預定由腳本量測提醒）、適用的文件類型。
- **正當性來源**：4.0.0 第二次新舊版對照。操作與壓力案例的新版變短或持平，決策報告給人讀的部分卻變長：3.1.0 是 3,376～3,760 字，4.0.0 第一輪是 3,308～3,866 字，第二輪整合後是 4,092～4,573 字。產出把「證據一、證據二、證據三」整組放進給人讀的部分，標題從 14 個增加到 19～20 個，建議還被排在「還不知道的事」之後。原因判斷：「主線留判斷所需的證據」「主要判斷就近標」「會影響結論的未知寫主線」「不利結果要留」每條都在往上方加內容，而上方沒有任何總量上限。這跟 WS-D09 診斷的情況相同：減法規則都是判斷題、沒有門檻，拉扯時一律輸給加內容的一側。
- **外部旁證**：業界寫報告摘要的慣例是約一頁、約全文 10%（[Georgia State 寫作指南](https://sites.gsu.edu/rcb-writing/executive-summary)、[Western Michigan](https://wmich.edu/business/executivesummary)，IEEE 也說執行摘要最長約可到全文 10%，見 WS-M07）。AR 25-50 §1-39b(7) 規範公文「多數一頁、附加資訊走附件」，只支持「受限主文加附件」這個形狀（同 WS-D09 的證據身分）。沒有來源直接支持 1,500 這個數字。
- **與已否決的「任何固定的段落句數上限」的差別**：被否決的是約束句段內部形式的數字，會誘導砍限定語湊數。本條約束的是可見層的總量，並強制指定去處（移到查證用的部分），限定語跟著主張留下，所以不在那條否決的範圍內。覆核時不得拿那條否決來刪本條。
- **與 WS-D09、WS-M01、WS-M09 的關係**：WS-D09 管開頭，本條管開頭之後到分隔線為止，兩者疊加。移到查證用的部分是移不是刪，符合 WS-M01。WS-M09 要求會改變理解的限制留在上方，本條不改這點，只限制每個結論帶的證據量。
- **失敗模式**：跟 WS-D09 一樣可能為了達標砍掉限制，或把多個證據擠成一句長句。紀錄顯示同步層長度「靠 prompt 守不穩、進 hook 才穩」，所以預算要靠腳本量測提醒，語意判斷（哪句限制必須留）留在 prompt。
- **日期**：2026-10-11。

## 4.0.0 新增規則的正當性分類

4.0.0 分三輪（後續第六、七、八輪見下）：第一輪依重構方案改結構、加圖；第二輪把一份外部 skill 當成現象，盤點本 skill 沒考慮完整的領域（需求不明、修改既有文件、文件類型、對話回覆、AI 雜訊、引用、團隊規範），逐項查共識後整合進既有結構，不是逐條往後補；第三輪依新舊版盲評的結果修正。

**第三輪的依據與證據強度**：3.1.0 與 4.0.0 各依同一批事實清單寫出決策、操作與五個壓力案例，交給另一家模型隱藏版本盲評（2026-10-11）。結果平手：好讀 4.0.0 贏 5 組、3.1.0 贏 4 組，準確各有輸贏。

4.0.0 的系統性問題是多開標題、同一結果在主線重講、證據細節留在主線、為補解釋補出材料沒有的事；兩版共同的問題是開頭交代過後又完整重講，而標成查證用的部分不會抵銷主線的負擔。

這是 AI 初篩，不是讀者實測，AI 評審有位置、篇幅與自我偏好的偏誤（Zheng 2023），樣本也只有 9 組。據此新增的規則都屬待驗證的設計選擇，以發版前驗證計畫的真人盲讀與實際文件回饋為準。

**發版前整體審查（2026-10-11，另一家模型唯讀審查全部變更）**：四項必修與處理如下。審查同樣只是 AI 判讀，不代替真人盲讀。

- 正確範例把推論寫成確定原因（迴圈「說明逾時為什麼越來越嚴重」、由部署時間宣告「問題出在快取設定」）：改成疑似機制加下一步驗證，同時把範例圖標題補上觀測範圍、方框拿掉未確認的「請求加倍」。
- 開頭上限與上方預算合併裁決，允許把必要主張移進不必讀的部分：衝突裁決表拆成兩列，上方預算只移佐證細節；「時間、筆數、錯誤碼放下方」改成依用途判斷（WS-M09、WS-M10）。
- 去重逼讀者回查（「見上一節」）：改成完整數字與證據只寫一次，理解當下主張所需的一句摘要可留（WS-M03）。
- 檢查腳本把一般水平線當成查證分界：屬腳本，由另一路處理。
- 建議項全部採納，方向都是讓文件更短：第一句交代狀態限於要決定或操作的文件、「材料未提供」限於影響判斷的缺口、「畫面待驗」限於依賴渲染的交付物、`diagrams.md` 不再宣稱腳本會檢查引號內的 Markdown 字串。
- 為了守住 SKILL.md 篇幅，衝突裁決表刪掉「必要前提與精簡」一列，必要前提的保護由第 2 節內容分流表的「主線」列承擔。

**第六輪：維護者盲讀與兩家好文件實例研究（2026-10-11）**：維護者盲讀新舊兩版後，偏好舊版的決策報告與新版的操作指南。

決策報告的回饋是：新版開頭沒先講發生什麼就要人決策、標題像金句、篇幅砍半後跳躍沒頭沒尾，兩版共有的「已觀測、推論」標籤都很煩。操作指南的回饋是：開頭就知道是不是寫給自己、步驟知道為什麼、故障排除表格說明為什麼要看。

為了分辨這是個人喜好還是有共識，兩家模型各自查公認好文件的實例（Design Docs at Google、Amazon PR/FAQ 與股東信、Cloudflare 與 GitLab 事故報告、Google SRE 範例、GOV.UK 寫作指引、Diátaxis、Google procedures、Stripe webhooks、ICD 203 等），六項都跟回饋一致。

維護者裁決照研究結果改。研究限制：部分來源只讀到二手轉載，樣本是公認範例不是普查，對台灣中文讀者的效果仍要實讀驗證。

| 規則 | 正當性分類 | 依據 |
| --- | --- | --- |
| 開頭第一段 2～4 句講全貌與結論，結論不晚於第二段 | 社群主流（2～4 句是本地實驗值） | [Design Docs at Google](https://www.industrialempathy.com/posts/design-docs-at-google/)、[Cloudflare 事故報告](https://blog.cloudflare.com/cloudflare-outage-on-june-21-2022/)、[Google SRE 範例](https://sre.google/sre-book/example-postmortem/)；GOV.UK 與 BLUF 是「重點最前」的反例，Minto 的情境、衝突、問題、答案與 AR 25-50「結論在第一或第二段」可調和 |
| 確定程度用自然語句，影響決定的判斷一定要說 | 移用推導加社群主流 | [ICD 203](https://www.dni.gov/files/documents/ICD/ICD-203.pdf)、[美國國家情報評估範例](https://www.dni.gov/files/ODNI/documents/assessments/NIE_Climate_Change_and_National_Security.pdf) |
| 標題用主題短語，不用問句或金句，操作指南章節可寫成任務 | 官方定論加社群主流 | [GOV.UK 寫作原則](https://www.gov.uk/government/publications/govuk-content-principles-conventions-and-research-background/govuk-content-principles-conventions-and-research-background)、[Diátaxis: How-to guides](https://diataxis.fr/how-to-guides/)；結論句標題是投影片慣例 |
| 不設固定篇幅，太長時依序處理，連接句不刪 | 社群主流 | [Amazon 2017 股東信](https://www.aboutamazon.com/news/company-news/2017-letter-to-shareholders)、[Amazon 文化與流程](https://www.aboutamazon.com/news/workplace/an-insider-look-at-amazons-culture-and-processes) |
| 操作指南：第一句寫適用的人與情境、每步一句原因、故障排除表格放最後 | 官方定論加社群主流 | [Google: Procedures](https://developers.google.com/style/procedures)、[Diátaxis](https://diataxis.fr/how-to-guides/)、[Stripe webhooks](https://docs.stripe.com/webhooks)、[GOV.UK 申請護照](https://www.gov.uk/apply-renew-passport) |
| 一句一件事，保留連接詞，不設中文字數門檻 | 官方定論 | [Google: Short sentences](https://developers.google.com/tech-writing/one/short-sentences)；中文字數門檻查無權威來源（見已否決主張） |


**第七輪：第二次盲讀與偏好證據查證（2026-10-12）**：維護者用四個沒讀過的新題目再盲讀一次，仍偏好舊版的形式。回饋重點：

- 段落太長會直接降低閱讀意願，尤其是開頭；短段落加粗體開頭方便掃讀。
- 「（作者建議，尚未定案）（已驗證有效）（已觀測）」這類標註很煩。理由是讀者本來就預設相信寫的人，一直強調某些地方可信，反而讓他懷疑沒標的地方，最後整份不是都標就是都不信。
- 步驟要能不用判斷照做，前提與解釋不要夾在步驟裡；選擇性動作藏在括號裡會讓人卡住；必要操作只給連結，讀者多半不會點，會直接找人求援。
- 標題要讓人知道為什麼要看這節，用熟悉的書面語；「範圍外」比「這份不涵蓋的事」難懂；表格欄名用書面語比口語好讀。
- 結尾一句「兩項都對上就完成了，任何一項對不上，看某一節」的導引很好用。

兩家模型各自查證這些偏好有沒有指南或研究支持，多數有。維護者同意照查證結果改。與 Anthropic 對文件「少粗體、少條列、用完整段落」的建議衝突的地方，依 WS-D04 以讀者實際回饋為準。

| 規則 | 正當性分類 | 依據 |
| --- | --- | --- |
| 段落約畫面三行（約 120 字）內，開頭更短，不為了短切斷因果 | 社群主流加讀者回饋，120 字是本地實驗值 | [澳洲政府寫作指南](https://www.stylemanual.gov.au/structuring-content/paragraphs)、[Google 技術寫作教材](https://developers.google.com/tech-writing/one/paragraphs)、Microsoft 與美國聯邦白話指南。腳本只提醒不阻擋。中文沒有段落長度研究 |
| 每段至多一個段首粗體短語，句中不加粗 | 官方定論加讀者回饋 | Google 只把粗體用在介面元素與段首小標（run-in heading）。與 GOV.UK 禁粗體強調、Anthropic 文件少粗體的建議衝突，依 WS-D04 以讀者回饋為準 |
| 不貼確定程度標籤，只在會改變決定的地方用一句自然的話說，整份少量 | 研究支持加讀者回饋 | [Kim 等 2019](https://scholarworks.iu.edu/dspace/bitstreams/c42704a8-1d6b-4c8d-b23c-2d10915cf015/download)：部分來源有評分時，沒評分的更受懷疑。[Pennycook 等 2020](https://pubsonline.informs.org/doi/abs/10.1287/mnsc.2019.3478)：只替部分內容加警示，沒加的反而被當成較可信。[警示疲勞研究](https://scholarsarchive.byu.edu/facpub/1955/)、[Google: Notices](https://developers.google.com/style/notices)。底線來自 ICD 203：會影響決定的推論仍要讓讀者知道還沒驗證 |
| 標題用讀者熟悉的書面短語，讓人知道為什麼要看，不用內部詞或行話 | 官方定論 | [Google: Headings](https://developers.google.com/style/headings)、[GOV.UK 清楚的語言](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)。美國聯邦指南偏好問句標題，本 skill 依讀者回饋不用 |
| 表格欄名用書面名詞（症狀、原因、處理） | 本地設計決策 | 在地語感，查無外部依據 |
| 前提集中在「開始前」，一步一個動作附完整指令，解釋不放進步驟，選擇性動作獨立成步 | 官方定論 | [Google: Procedures](https://developers.google.com/style/procedures)、[Microsoft: 逐步說明](https://learn.microsoft.com/en-us/style-guide/procedures-instructions/writing-step-by-step-instructions)、Diátaxis 操作指南「只有動作」 |
| 完成任務必要的操作寫進本文，原始連結附旁 | 讀者回饋（WS-D04） | 與 Google、GOV.UK「連結不重複內容」的主流相反。主流站在維護者角度，本 skill 站在照做者角度 |
| 指令、路徑、設定值放程式碼區塊，敘述段落少夾行內程式碼 | 社群主流（零星支持） | [Google: Code in text](https://developers.google.com/style/code-in-text) |
| 操作或驗證結尾一句說怎樣算完成、不成功看哪一節（寫節名） | 社群主流 | Google 先動作後結果、Carroll 極簡主義的錯誤回復 |
| 開頭前兩句交代發生什麼、寫給誰、讀完要做什麼（取代第六輪的「第一段 2～4 句」） | 官方定論加讀者回饋 | Microsoft 讓讀者一眼認出是不是寫給自己、[Google 技術寫作：文件開頭](https://developers.google.com/tech-writing/one/documents)、Anthropic 的 re-grounding 寫法。仍受 WS-D09 上限約束 |
| 每節能單獨讀，不寫「上面、下面、上一節」 | 社群主流 | AI 助理的回答原則（Codex、OpenAI Model Spec、Anthropic）可搬到文件的部分。「一行片段取代完整句子」只適合對話，不搬 |

與已否決主張的關係：「任何固定的段落句數上限」否決的是句數硬門檻；第七輪的 120 字是畫面行數的軟提醒，不誘導砍限定語，因果放不下時寧可多一行。「段落字元門檻未校準前不採用」由維護者明確回饋重開（重開條件第一條），改為 120 字、只提醒不阻擋，仍待實際文件校準誤報率。

**第八輪：實際使用盤點（2026-10-16）**：維護者 10 月 13 日到 16 日用新版寫實際工作文件（技術說明、工單、首頁、給其他團隊的修正清單），盤點產出與維護者當場的指正後修改，維護者裁決必修與建議一起改。依據全是讀者回饋（WS-D04），除了收合的禁令沿用既有外部依據，沒有另查外部共識。限制：單一讀者、四天的使用紀錄，不是普查。

| 規則 | 正當性分類 | 依據 |
| --- | --- | --- |
| 日常說法指讀者平常講的詞，不是字面中譯、不自創譯名，產品與系統用團隊慣用名稱 | 讀者回饋（WS-D04） | 盤點：token 譯成「權杖」、middleware 譯成「中介程式」，自創「產品標頭」「放行清單」，產品名跟團隊週報用的名稱對不上。術語階梯第一階原本只寫「日常說法」，被執行成字面中譯。補上這條也是 WS-D03「不硬翻成生造中文」在術語階梯上的落實 |
| 給人讀的部分不出現讀者手上沒有的文件、內部編號、工具欄位與作業狀態詞，列入驗收第 5 項 | 讀者回饋，延伸 WS-M05（代號首次出現附意義）與 WS-M08（以共同場合出現過的詞為界） | 盤點：引用讀者沒有的文件、作者自編的分類代號、掃描工具的欄位名、「查不到」「未分級」這類作業狀態詞。WS-M05 只要求定義，這類東西就算定義了讀者也用不上，所以改寫成它代表的事 |
| 查證細節與決策背景在支援收合的平台預設收合，會改變判斷的不收 | 讀者回饋，禁令沿用外部依據（NN/g、GOV.UK，見外部依據表） | 維護者兩次要求細節預設收合，原話「以後也請這樣寫」。取代原本「三個條件同時成立才可收合」，屬 WS-D06 可調部分。禁令補上「緊貼主張的限制」與「讀者要先懂才能判斷的經過摘要」，守 WS-M09 與 `doc-types.md`「決策與設計」 |
| 工單骨架（標題功能加影響；影響、問題出在哪、修法、怎樣算完成）與待裁決骨架（建議、不決定會怎樣、選項、決策人，細節收合）；觸發條件加入 Jira 單、GitHub Issue 與 PR 說明 | 讀者回饋，本地決策 | 維護者對待裁決單的回饋：「可以，以後也請這樣寫」。四段段名是本地決策，查無外部共識。PR 說明沿用同一套是維護者派工時加入，沒有實際使用紀錄 |
| 總覽或首頁一頁看完，逐項細節移到子頁 | 讀者回饋，與既有「篇幅暴增就拆檔」同向 | 一份首頁 738 行時一直被說太長，改成 48 行（事實在前、每項一行加工單連結）後不再被抱怨 |
| 格子要寫句子時改成一項一塊的條列 | 讀者回饋 | 「GitHub 上表格很難讀都擠成一坨」。原本是外部依據表的本地加註（儲存格過長改小標加條列），這輪寫進 `SKILL.md` 形式表 |
| 要對照的項目（Endpoint、路徑、行號）用固定格式子項目一行一個，不用頓號串在句中 | 讀者回饋 | 「不要用頓號，直接段落符號不好嗎」 |

讀者滿意、要求照樣寫的四種形式收成 `examples.md`「工單、首頁與修正清單的範例」，情境全部改寫成虛構：工單四段、待裁決單（細節收合）、一頁看完的首頁、每項固定子項目的修正清單。

為了把 `SKILL.md` 守在 4,500 字元內，這輪移出或合併的內容（規則本身都還在，只是不在本文重講）：

- 操作步驟的細則（解釋放步驟外、選擇性動作「沒有的話：」、必要操作寫進本文、結尾導引）只留在 `doc-types.md`「操作」，本文留「照做不用判斷、前提集中在開始前」與路由。這幾條是第七輪的讀者回饋，移出後靠 `doc-types.md` 承載。
- 平台不明預設用文字只留在 `diagrams.md`。圖的文字替代不放進「不必讀」那句只留在 `diagrams.md` 與 `examples.md`「圖的寫作面」。
- 「其他地方只留一句摘要」由衝突裁決表「自我完整與不重複」那列承擔，第 2 節不重講。
- 「確定要轉寄時寫一行附哪幾節」移出本文，第九輪隨裁切流程一起撤銷。狀態型文件標日期與狀態只留在 `doc-types.md`「狀態更新」與 `examples.md`「引用與連結」。

觀察到但只出現一次、先不改的兩件事：猜錯讀者要做的事（讀者要的是先修哪些，產出寫成怎麼回覆對方），以及「複述待驗」每次附三題但讀者從未回應，考慮改成只在文件標註。重複出現再依重開條件處理。

**第九輪：不再分兩個版本、查證用的部分收合（2026-10-17）**：維護者實際使用後兩項回饋，都屬讀者回饋（WS-D04），維護者裁決照建議改。

| 規則 | 正當性分類 | 依據 |
| --- | --- | --- |
| 一開始就寫給讀者的那一份，不另寫內部版與分享版兩個檔；只有把工作檔轉給別人前才跑外流檢查。`examples.md` 那節改名「轉給別人前的檢查」，六步裁切流程縮成外流清單、人稱與詞彙界線 | 設計決策重開（WS-D08，重開條件第一條） | 維護者原話：「我搞不懂為什麼還有分享版跟什麼版」。改寫理由與新的不變條件見 WS-D08。WS-D07 人稱與 WS-M08 詞彙界線的行為目標不變，只把適用對象從「分享版」改寫成「會被轉發」「轉給主管或其他團隊」的文件 |
| 分兩部分時，查證用的部分放進收合區塊；分隔線與「以下供查證」那行留在外面 | 讀者回饋，延續第八輪的預設收合 | 維護者原話：「是不是新版預設都不會收合了？我看一堆細資料攤在下面展開又叫人不要讀」。第八輪只在收合規則裡寫，`SKILL.md` 第 2 節分兩部分那條沒寫，執行時就只寫「不必讀」卻整段展開。這輪寫進那條，`doc-types.md` 的決策與設計、事件報告骨架同步改成收合。「以下供查證」那行留在外面，是因為檢查腳本靠它辨識分界 |

外部依據表標「官方定論」只代表來源明文要求，不代表已證明適用所有工作文件。新規則依來源關係分三類：

- **來源直接要求**：圖要有文字替代、顏色不單獨承載意義（WCAG，限網頁呈現的文件），以及白話摘要與全文一致（Cochrane）。
- **移用到本 skill 的推導**：來源原本約束別的文件類型，移用時寫明理由。例如 ICD 203 約束情報分析產出，移用理由是調查報告同樣要讓讀者分辨觀測與推論。Mayer、Chandler 與 Sweller 的對象是學習材料，Kalyuga 是學習情境，Minto 是顧問報告。
- **待驗證的設計選擇**：本地決定的可調預設，不列為必守條款。

| 規則 | 分類 | 依據 | 邊界 |
| --- | --- | --- | --- |
| 依讀者對題目的熟悉度決定解釋多深 | 移用推導 | Kalyuga 等 2003 專家反轉效應 | 研究型產出預設不熟仍由 WS-D05 決定 |
| 形式表加入圖、圖表、時間線 | 移用推導 | ICD 203 §6.b.(9)、Few 2006、EU 與 CDC 時間線元件 | 圖能降低理解成本才畫，不強制先畫 |
| 顏色不單獨承載意義、需要解讀的記號附圖例 | 來源直接要求 | WCAG 2.2 1.4.1 | 限網頁呈現的文件，其他環境沿用 |
| 同一份文件的視覺記號一致 | 移用推導加本地延伸 | 同上 | 「一致」是本地延伸 |
| 線型區分已觀測與推論 | 社群慣例加研究支持，本地約定 | RFFlow、Boukhelifa 2012 | 必附圖例，不當通用標準。交接評估中，不知道這條規則的寫手兩次把未驗證的因果畫成實線，跟自己的正文矛盾 |
| 圖標題、方框與箭頭受五種限制約束 | 移用推導 | ICD 203 §6.b.(9) 要求圖遵守同樣的分析標準 | 箭頭要分辨時間先後、相關或因果假說，不只靠線型 |
| 圖與文字分工 | 移用推導 | W3C 複雜圖、Chandler 與 Sweller 1991、Rop 2018 | 刪的是沒有額外用途的逐項重述，不是一律刪 |
| 文字替代的預設位置 | 待驗證的設計選擇 | 無 | 依平台與讀者調整，不放在標「不必讀」卻是部分讀者必需的地方 |
| 確定程度用自然語句、不貼標籤（取代 4.0.0 第一輪的「證據標示分三面向、各用一套詞」，第七輪收緊成整份少量、只在會改變決定處說） | 移用推導加社群主流 | ICD 203 要求主要判斷標確定程度；好文件實例不逐句貼標籤，事實直述、推論當句限定、依據集中一節 | 影響決定的判斷一定要說，五種限制的底線不變 |
| 主要判斷就近標、相同標示可共用（已由上一列取代） | 移用推導加本地延伸 | ICD 203 主要判斷標可能性與信心 | 盲讀回饋：標籤一多就成為雜訊。改寫後主要判斷仍要說確定程度，但用當句的一個詞，不用標籤 |
| 影響結論、信心或行動的未知寫在主線 | 移用推導 | ICD 203 知識缺口、IPCC | 限會影響結論、信心或行動的未知 |
| 掃讀的可觀察判準 | 待驗證的設計選擇 | WS-D01 可調部分 | 搭配最長區塊抽查 |
| 平台不明時預設文字 | 待驗證的設計選擇 | 無 | 需要圖時可附 Mermaid 並給完整文字替代 |
| Graphviz 共用樣板 | 待驗證的設計選擇 | 交接評估的實測 | 適用內建 viz.js 2.1.2 的環境 |
| 架構圖由整體逐層放大 | 社群主流 | C4 模型 | 每張圖一層，從系統脈絡開始 |
| 粗體只給需要一眼找到的地方 | 待驗證的設計選擇 | 評估觀察：3.1.0 與提案版正文粗體 12～22 個 | 跟已否決的 Bionic Reading 式加粗無關 |
| 開頭讓讀者知道全部待決範圍 | 待驗證的設計選擇（WS-D09 可調部分） | 評估觀察 | 不改 5 個主張與 400 字元的上限 |
| 確定要轉寄時寫一行附哪幾節（第九輪撤銷） | 待驗證的設計選擇 | 評估觀察 | 不再有兩個版本，轉出時靠 WS-D08 的外流檢查 |
| 驗收分層與「畫面待驗」 | 待驗證的設計選擇 | 無 | AI 做不到的標待驗，不假裝已檢查。「畫面待驗」限依賴渲染的交付物（有圖、會貼到其他平台），純文字回覆不用 |
| 審查同時問失真與更累 | 設計決策 | WS-D10 | 兩者同等權重 |
| 需求不明時，不同解讀會寫出實質不同的文件才先問 | 移用推導 | Anthropic〈Delivering work〉、OpenAI Model Spec、GOV.UK 使用者需求 | 原本約束 AI 助理的互動；其餘情況寫明假設繼續 |
| 對話回覆寫成「何時用格式」 | 來源直接要求 | Anthropic〈Formatting in chat〉、OpenAI Model Spec | 不寫禁令，理由見已否決主張 |
| 刪掉不改變判斷的句子，但真的不確定要說清楚 | 移用推導加研究支持 | ICD 203、Anthropic 開場建議、Kim 等 2024 | 雜訊清單是觀察整理，不是禁用詞表 |
| 推理依據要寫，作業流水帳不寫 | 移用推導 | ICD 203 要求說明判斷依據 | 依據是讀者判斷所需，過程不是 |
| 連結文字描述目的地、直接引用標示 | 來源直接要求 | Google Link text、Anthropic 對摘要轉述的提醒 | |
| 程式碼連結用固定版本 | 來源直接要求 | GitHub 固定連結說明 | 檔案與行號的寫法只當慣例 |
| 絕對日期、狀態型文件標日期與狀態 | 社群主流 | Google 文件寫作建議（刪過時內容） | |
| 修改既有文件：維護不堆積、同步開頭、拆檔、刪過時內容 | 社群主流 | Google 文件寫作建議、Wikipedia 導言寫法、Design docs at Google、Gooding 等 2025 | 決策紀錄例外，另開新紀錄取代 |
| 依文件類型的骨架 | 社群主流 | Diátaxis、DITA、The Good Docs Project、Design docs at Google、Google SRE | 是鷹架不是範本，不建空結構 |
| 決策與設計型文件寫非目標 | 社群主流 | Design docs at Google | 寫在 `doc-types.md` |
| 專案或團隊規範優先於本 skill | 社群主流 | Google developer documentation style guide | 偏離時全文一致 |
| 同一清單格式一致（第七輪起，短段落加段首粗體短語是預設的掃讀形式） | 社群主流 | 各家 style guide 的清單一致性要求 | 段首粗體的依據見第七輪紀錄 |
| 給人讀的部分預算約 1,500 字（已撤銷，見 WS-M10） | 混合型決策 WS-M10 | 第二次新舊版對照 | 由「不設固定篇幅、太長時依序處理」取代 |
| 決策型文件的順序：開頭一段講全貌與結論，接著是要決定的事或依發生順序的經過，再來原因與依據、未知 | 社群主流 | 事故報告、設計文件、PR/FAQ 實例；盲讀回饋 | 取代「開頭之後第一節就是要決定的事」。寫在 `doc-types.md` |
| 開頭第一段 2～4 句講發生什麼、為什麼現在處理、結論或要讀者做什麼，結論不晚於第二段（取代第三輪的「第一句交代決定或動作狀態」，第七輪再整合成「前兩句交代發生什麼、寫給誰、讀完要做什麼」） | 社群主流，2～4 句是本地實驗值 | 好文件實例與盲讀回饋，見下方第六輪紀錄 | 仍受 WS-D09 的 5 個主張與 400 字元上限約束 |
| 標題、粗體句、圖標題與箭頭不比材料更確定，只看到先後就寫先後 | 移用推導 | ICD 203 §6.b.(9) 要求圖遵守同樣的分析標準，延伸到所有醒目位置；第三輪盲評觀察 | 讀者常只看醒目位置 |
| 缺口會影響判斷時寫「材料未提供」，不為解釋順而補；不相關的缺資料不逐項列 | 移用推導 | ICD 203 要求說明知識缺口；第三輪盲評觀察 | 未記載不等於不存在或未通過驗證 |
| 同一個事實的完整數字與證據只寫一次 | 待驗證的設計選擇 | 第三輪盲評觀察；發版前整體審查修正 | 取代舊的「自我完整以小節為單位、必要的重述允許」，那句實際上允許了整份重複。理解當下主張所需的一句摘要可以留（WS-M03 自我完整），只寫「見上一節」會逼讀者回查。操作上必要的提醒可重複 |
| 規則的例外與未定邊界放在讀者套用之前 | 待驗證的設計選擇 | 第三輪盲評觀察，與 WS-D06「必要前提放在操作前」同向 | |
| 短文件不分節，讀者需要跳讀或回查才加標題 | 待驗證的設計選擇 | 第三輪盲評觀察，與 Anthropic 對話格式建議同向 | |

另外兩項紀錄：

- **美感**：可以另外測讀者偏好與舒適度，但不代替正確性與可用性驗收。Tractinsky 1997 測的是美感與「覺得好用」的相關，不是實際好不好用。
- **SKILL.md 篇幅以 token 為準**：Claude Code 在 auto-compact 後每個 skill 只重貼前 5,000 token，同一 session 叫用的 skill 共用 25,000 token（[Claude Code skills 文件](https://code.claude.com/docs/en/skills)「Skill content lifecycle」，2026-10-11 核對）。4.0.0 的 SKILL.md 目標 4,500 token 內，必守條款放在最前面，萬一超出也只切掉後段。前置只能降低被丟掉的風險，不能保證保留。為了守住篇幅，事件報告的寫法放在 `doc-types.md`；「會改變判斷的但書緊貼主張」寫在衝突裁決表開頭，「相同強度只標一次」寫在第 4 節，表內不重複。

## 外部依據（可依新證據修改）

以下規則的正當性來自外部規範，證據變動就跟著調整；表內標注「本地加註」「本地推導」「本地補充」的部分是本地決策，不隨外部證據變動：

| 規則 | 來源 | 適用範圍與注意事項 |
| --- | --- | --- |
| 每項 3 個以上屬性要對照就用表格 | [Google Style Guide: Tables](https://developers.google.com/style/tables) | 判準看屬性數不看項目數。本 skill 另加輔具、窄螢幕、格子要寫句子三個例外，改成一項一塊的條列，屬本地加註，不是原始來源的立場（第八輪讀者回饋寫進 `SKILL.md` 形式表） |
| 清單 2–7 項 | [Microsoft Style Guide: Lists](https://learn.microsoft.com/en-us/style-guide/scannable-content/lists) | 官方寫的是建議值。其常被連結的 Miller 7±2 在認知科學界已被視為過度簡化，不要拿來當科學依據 |
| 只有 1~2 列不要做表格 | [Australian Style Manual: Tables](https://www.stylemanual.gov.au/structuring-content/tables) | 「表頭比內容重」是本地補充的理由，原文沒有 |
| 名詞連用三個以上就難讀 | [digital.gov: Plain language — writing style](https://digital.gov/guides/plain-language/writing/style)（plainlanguage.gov 原頁已於搬遷後併入，舊網址 301） | 門檻確為 3，原文措辭更強（beyond three, the string becomes unbearable） |
| 斜線不可分隔替代選項、`&` 不可代 and | [Google: Slashes](https://developers.google.com/style/slashes)、[Word list](https://developers.google.com/style/word-list) | `&` 規則對 UI 元件、表頭、程式碼有例外 |
| 術語處理階梯（能換就換 → 保留＋首次說明 → 大型文件才建 glossary） | [Google: Jargon](https://developers.google.com/style/jargon)、[Microsoft: Use technical terms carefully](https://learn.microsoft.com/en-us/style-guide/word-choice/use-technical-terms-carefully)、[GOV.UK Technical A–Z](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/style-guides/technical-a-to-z/) | 前兩階有外部支持：各家都反對把必要術語砍光，Google 支持保留讀者會拿去搜尋的術語（原文是「readers search for those terms」與 SEO，非逐字 searchability）。**第三階「大型文件才建 glossary」是本地推導**：Google 與 Microsoft 該頁均未提 glossary（2026-08-02 查證），不能列為多家共同規則；規則保留，該階證據身分為本地 |
| 事件報告聚焦系統不聚焦個人，action item 要有 owner | [Google SRE Book: Postmortem Culture](https://sre.google/sre-book/postmortem-culture/) | 社群有「blame-aware」的修正意見，認為純 blameless 不符合人的實際反應 |
| 標點規範 | 教育部《重訂標點符號手冊》修訂版（2009） | 台灣現行的官方標點規範。不採 GB/T 15834——兩岸的分號定義、引號、標點位置有落差 |
| 收合區塊的語法與基本用法 | [GitHub Docs: Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections) | 只支撐「怎麼用」。本 skill 的四類分流、處理順序與收合的條件與禁令屬 WS-D06，不是從這份文件推導 |
| 重要資訊不得藏在收合區塊裡 | [NN/g: Accordions on Desktop](https://www.nngroup.com/articles/accordions-on-desktop/)、[GOV.UK Details](https://design-system.service.gov.uk/components/details/)、[GOV.UK Accordion](https://design-system.service.gov.uk/components/accordion/) | NN/g：「Avoid hiding any crucial information within the collapsed panels」。GOV.UK 更嚴：details 只適合部分使用者需要的資訊；所有人都需要的內容應該先試簡化或拆頁，不是收合 |
| 教學先讓讀者動手、背景不擋路 | [Diátaxis: Tutorials](https://diataxis.fr/tutorials/) | 主要支持是 Diátaxis。Google Procedures 只規範步驟寫法，且要求讀者能事先取得準備任務所需的資訊——歸在「必要 prerequisite 放操作前」那一側，不能並列為本規則的共同支持（2026-08-02 更正）。**不是無條件追求步驟最少**。[DITA task elements](https://docs.oasis-open.org/dita/v1.1/OS/langspec/common/task2.html) 與 [Write the Docs](https://www.writethedocs.org/guide/writing/docs-principles/) 支持把真正必要的 prerequisite 放在操作之前。查過 Google、Microsoft、DITA、Diátaxis、W3C，**沒有**任何一家主張完整詞彙表該放教學前面 |
| 一個步驟對應一個讀者決定 | [Google: Procedures](https://developers.google.com/style/procedures)、[Microsoft: Step-by-step instructions](https://learn.microsoft.com/en-us/style-guide/procedures-instructions/writing-step-by-step-instructions) | 兩家都允許把同一操作位置上的小動作合併，也允許步驟附帶必要結果或理由。**「每個項目只能含單一資訊」會過度切碎**，不是共識 |
| 連結節制 | NN/g「A Link is a Promise」、[Google: Cross-references](https://developers.google.com/style/cross-references) | Google 現行立場是把連結放在最有用的位置；長頁面、多入口時可以重複。正文的「預設只連首次」已寫入這個例外 |
| 一段一概念、不設固定句數 | [Google: Paragraph structure](https://developers.google.com/style/paragraph-structure) | 現行立場是一句或超過六句都可能合理。正文據此改用「一段一個推論單位」的可觀測判準 |
| 認知可及性 | [W3C COGA: Making Content Usable](https://www.w3.org/TR/coga-usable/design_guide.html) 4.4.1、4.4.3、4.4.5、4.4.8、4.4.9、4.4.12 | 屬補充指引，不是 WCAG 強制條款 |
| 好讀的四項原則：讀者拿到需要的、找得到、看得懂、用得上，並與讀者一起評估 | [ISO 24495-1 預覽](https://cdn.standards.iteh.ai/samples/78907/d194fac21d6a45f38bfcfec9657f7498/ISO-24495-1-2023.pdf) | 官方定論。WS-D10 目標的操作定義與驗收骨架 |
| 主要訊息先行、依讀者任務組織內容 | [Digital.gov: Organize](https://digital.gov/guides/plain-language/principles/organize)、AR 25-50、[ICD 203](https://archive.dni.gov/files/documents/ICD/ICD-203.pdf) §6.b.(6) | 官方定論。支撐開頭與內容安排 |
| 去除無關內容 | [Fiorella 與 Mayer](https://www.cambridge.org/core/books/abs/cambridge-handbook-of-multimedia-learning/principles-for-reducing-extraneous-processing-in-multimedia-learning/F29A19FCD34C542806F736E0661C05F5) | 研究支持，對象是學習材料（23 個實驗中 23 個支持）。移用為精簡與主線判準 |
| 自我說明的靜態圖再加重述文字會妨礙理解 | [Chandler 與 Sweller 1991](https://doi.org/10.1207/s1532690xci0804_2)、[Sweller 2023](https://link.springer.com/article/10.1007/s10648-023-09817-2)、[Rop 2018](https://onlinelibrary.wiley.com/doi/full/10.1002/acp.3445) | 研究支持但有爭議，Rop 2018 未完整重現。只支撐「刪掉對任務無益的重述」，不支撐一律刪 |
| 複雜圖要有可取得的詳細文字替代，顏色不能單獨承載意義 | [W3C 複雜圖](https://www.w3.org/WAI/tutorials/images/complex/)、[WCAG 2.2 1.4.1](https://www.w3.org/TR/WCAG22/#use-of-color) | 官方定論，直接適用網頁呈現的文件。W3C 也建議在伴隨文字中指出複雜圖的重點 |
| 專家反轉效應：對熟悉題目的讀者，輔助說明變成負擔 | [Kalyuga 等 2003](https://www.tandfonline.com/doi/abs/10.1207/S15326985EP3801_4) | 研究支持，學習情境。移用為「依題目熟悉度增減解釋」 |
| 條列有條件效益：改善項目記憶、傷害周邊文字記憶 | [Jansen](https://research-portal.uu.nl/en/publications/how-bulleted-lists-and-enumerations-in-formatted-paragraphs-affec/) | 研究支持。4.0.0 據此撤掉因果推導預設轉條列 |
| 主要判斷標可能性與信心，區分資訊與判斷，說明影響結論的知識缺口 | [ICD 203](https://archive.dni.gov/files/documents/ICD/ICD-203.pdf)、[IPCC 不確定性指引](https://www.ipcc.ch/site/assets/uploads/2018/05/uncertainty-guidance-note.pdf) | 官方定論，原本約束情報分析與氣候評估。移用到調查報告的理由是讀者同樣要分辨觀測與推論 |
| 資訊用圖比文字清楚時用圖，圖遵守同樣的分析標準 | ICD 203 §6.b.(9) | 官方定論，移用。支撐畫圖時機與圖標題受限制約束 |
| 關聯圖以實線、虛線區分已確認與推測，受試者偏好虛線表示不確定 | [RFFlow](https://www.rff.com/link_analysis.htm)、[Boukhelifa 2012](https://www.aviz.fr/Research/UncertaintySketchy) | 社群主流加研究支持。本 skill 當成必附圖例的約定，不當通用標準 |
| 同組同種類、上層摘要下層 | [Minto](https://barbaraminto.com/concept) | 社群主流（顧問報告）。支撐「一段聚焦一個問題」，不支撐硬拆成結論加理由 |
| 白話摘要與全文結果一致 | [Cochrane Chapter III](https://www.cochrane.org/authors/handbooks-and-manuals/handbook/current/chapter-iii) | 官方定論，來源直接要求。支撐兩部分不矛盾 |
| 複述測試 | [Digital.gov: Paraphrase testing](https://digital.gov/guides/plain-language/test/paraphrase-testing/) | 官方定論。支撐複述驗收 |
| AI 評審有位置、篇幅與自我偏好的偏誤 | [Zheng 2023](https://arxiv.org/abs/2306.05685) | 研究支持。AI 審查只當初篩，評時隱藏版本、對調順序 |
| 查確切數字用表格，看趨勢、模式與例外用圖表 | [Few 2006](https://public.dhe.ibm.com/software/data/sw-library/cognos/pdfs/whitepapers/wp_visual_communications_core_design_principles.pdf) | 社群主流（資料視覺化經典） |
| 時間線用於強調先後的事件，少於三項不用，不用來表示步驟 | [EU 元件庫 Timeline](https://ec.europa.eu/component-library/v4.0.0-beta-1/eu/components/timeline/usage)、[CDC Timeline](https://www.cdc.gov/wcms/4.0/cdc-wp/special-purpose/timeline.html) | 官方設計系統 |
| 架構圖由系統脈絡逐層放大（脈絡、容器、元件、程式碼） | [C4 模型](https://c4model.com/) | 社群主流。寫在 `diagrams.md` |
| SKILL.md 本文 500 行內、細節按需載入、以實際任務評估 | [Anthropic skill best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) | 官方定論。4.0.0 另以 token 為篇幅單位（見上節） |
| 需求不明時，只有不同解讀會導致實質不同的成果才先問，問題放在已交付內容的末尾 | [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)〈Delivering work〉、[OpenAI Model Spec](https://model-spec.openai.com/2026-08-18.html)、[GOV.UK: Identify user needs](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/plan-manage-content/identify-user-needs) | 官方定論，有條件。反例兩側都有：模型普遍太少問（[CLAMBER](https://arxiv.org/html/2405.12063v2)），Anthropic 也警告不必要的確認會卡住工作 |
| 文件隨變更更新、刪過時內容，開頭摘要全文、開頭提到的本文都要有，過長拆子題 | [Google docguide best practices](https://google.github.io/styleguide/docguide/best_practices)、[Wikipedia MOS:LEAD](https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Lead_section)、[Design docs at Google](https://www.industrialempathy.com/posts/design-docs-at-google/) | 社群主流。AI 多輪編修會加字、偏離原意（[Gooding 等 2025](https://arxiv.org/html/2503.19711v1)，預印本）。決策紀錄是例外，另開新紀錄取代 |
| 依讀者任務分文件類型 | [Diátaxis](https://diataxis.fr/how-to-use-diataxis/)、[DITA 1.3 information typing](https://docs.oasis-open.org/dita/dita/v1.3/cos02/part1-base/archSpec/base/information-typing.html)、The Good Docs Project | 社群主流。Diátaxis 自稱不是範本、不要建空結構（[Field Guide](https://stevearrants.substack.com/p/documentation-frameworks-a-field)） |
| 一般對話預設段落，面向夠多才條列，最後總結能單獨讀懂 | [Anthropic prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)〈Formatting in chat〉、OpenAI Model Spec「Adapt length and structure to user objectives」 | 官方定論。Anthropic 也提醒為壓格式寫的規則會壓掉需要的結構 |
| 說明不確定性如何影響判斷，第一人稱不確定說法降低過度依賴，「可能」的理解差異大 | [ICD 203](https://archive.dni.gov/files/documents/ICD/ICD-203.pdf)、[Kim 等 2024](https://arxiv.org/abs/2405.00623)、[How likely is likely](https://www.jasoncollins.blog/posts/how-likely-is-likely) | 官方定論加研究支持（Kim 等 N=404）。支撐「刪雜訊但不刪真的不確定」 |
| AI 寫作的常見跡象 | [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) | 觀察清單，不是規則。Anthropic 另建議不加「Here is…」式開場 |
| 連結文字描述目的地，程式碼連結用固定版本 | [Google: Link text](https://developers.google.com/style/link-text)、[GitHub: 固定連結](https://docs.github.com/en/repositories/working-with-files/using-files/getting-permanent-links-to-files) | 官方定論。檔案與行號的寫法查無官方規範 |
| 專案規範優先於通用 style guide，偏離時全文一致 | [Google developer documentation style guide](https://developers.google.com/style) | 社群主流。Google 自稱是 guidelines not rules。團隊詞彙表可用 Vale 這類工具做機械檢查 |

## 已否決的主張

查過但**不採用**，且**不得因為在寫作圈流行就重新加回**。加回前請先讀「為什麼」欄。

| 主張 | 判定 | 為什麼不用 |
| --- | --- | --- |
| 「79% 讀者掃讀而非逐字讀」 | 已否決當作依據 | 出自 1997 年的 web 瀏覽研究，NN/g [2008 年已改用](https://www.nngroup.com/articles/how-little-do-users-read/)「平均只讀 20-28% 字數」的框架。兩組數字都是 web 行為，不能外推到工作文件。掃讀預設改由 WS-D01 支撐，不需要比例數字 |
| 「GOV.UK 規定段落上限 5 句」 | 外部確有此規範，本地不採用 | 2026-08-02 更正：GDS 官方指引確有「Paragraphs should have no more than 5 sentences each」（[Writing to GOV.UK standards](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)），先前判定「查無此出處」是查證錯誤——只查了主 style guide，漏了 publishing 指引；「查無來源」這類否定命題要查官方站內搜尋、現行頁面與搬移頁面才能下。句長 25 字的規定同頁並存。ONS service manual 另訂 4 句。規則不變（見下一列），只改證據身分 |
| 任何固定的段落句數上限 | 不採用（本地裁決） | 外部有規範但數字互不一致（GOV.UK 5 句、ONS 4 句、Google 不設數字），且固定數字會製造「為了符合形式而過度壓縮」的問題；使用者已裁決不用固定句數作硬門檻。改用「一段一個推論單位」的可觀測判準。**同步層預算（WS-D09）不在此列**（給人讀的部分的預算 WS-M10 已撤銷）：被否決的是約束句段內部形式的數字，WS-D09 約束的是可見層的主張總量並強制指定去處 |
| 「中文一句 20 字內最佳、40 字是上限」 | 查無來源 | 只找得到零星部落格的「15-25 字」建議，無學術或官方來源。改用可觀測的重讀觸發器取代字數門檻 |
| 「破折號堆疊是 AI 生成特徵」 | 降級為弱訊號 | 屬流行認知，會誤傷本來就慣用破折號的作者。破折號限量的理由改用可讀性（過量或關係不明會妨礙理解） |
| 「BLUF、inverted pyramid、Minto、GOV.UK 四個體系同向」 | 引用有誤 | HBR 2016 原文只提 BLUF 與 inverted pyramid 相似，沒提 Minto。Minto 的核心是歸納／演繹論證階層，跟純重要性排序不同。**否決的是「四體系同向」這個宣稱，不是 Minto 本身**——Minto 在「主要結論在上、上層概括其下層論點」這個論點階層的用途上仍是有效來源（見 WS-M07）。但它不直接支持「分層服務不同角色」，那是本地延伸 |
| 用 Diátaxis 當「讀者範圍」的分層依據 | 接錯軸 | Diátaxis 分的是讀者當下的需求情境（學習／解決問題／查閱／理解），不是讀者身份或知識程度 |
| 「無人稱語域是 BLUF／briefing note 的傳統要求」 | 引用有誤 | AR 25-50 第 1-39.b.(6) 明文要求 correspondence 用 I、you、we 當句子主詞，方向與無人稱相反；加拿大 briefing note 指南只規定內容客觀（不寫個人意見），不規範文法人稱——內容客觀性與文法人稱是兩條規則，不能混為一談。**否決的是歸屬宣稱，不是無人稱本身**：無人稱的正當性由 WS-D07 承載（轉發時指涉錯亂的功能依據），不掛任何權威傳統名下 |
| Jansen (2014) 的 bullet 研究可當無條件通則 | 過度簡化 | 原文是五個分研究的有條件結果：三個發現 bullet 有助清單記憶（項目異質時效果減弱）、兩個發現傷及周邊段落記憶，但讀者對文章整體評價反而更好。4.0.0 據此撤掉「因果推導預設轉條列」（見 WS-D01） |
| Bionic Reading 式加粗（每個字前半段加粗） | 不採用 | 2024-2025 多篇對照研究（含眼動追蹤）未發現速度或理解上的效益，例如 [Acta Psychologica 2024](https://www.sciencedirect.com/science/article/pii/S0001691824001811)，部分研究另觀察到負面效果。泛稱「標記關鍵字有助聚焦」則屬社群主流、無直接對照實驗 |
| 用 WCAG 2.2 SC 3.1.5 Reading Level 當硬門檻 | 不採用 | 它是 web 的 AAA 條款，對一般文件過嚴；COGA 的條目對本 skill 更直接 |
| 用「3-30-300」當分層結構的名稱 | 不採用 | 這個名稱出自 [Kurt Buhler, SQLBI, 2024-06-03](https://www.sqlbi.com/articles/introducing-the-3-30-300-rule-for-better-reports/)，用於 Power BI 儀表板，概念源頭是 Shneiderman 1996 的 visual information-seeking mantra。原文的「30 秒」是 filter 與 zoom 這類互動操作，靜態文件沒有這個動作。本 skill 曾誤把它當成通用的文件寫作慣例，改用 Executive Summary → Body → Appendix（見外部依據表）。同名不同義的還有行銷的「3-30-3 rule」（末段是 3 分鐘）與都市林業的「3-30-300 rule」（3 棵樹、30% 樹冠、300 公尺綠地） |
| 讀者可讀性分數（Flesch-Kincaid 之類）當通過標準 | 不採用 | 屬工具與顧問慣例，非 plainlanguage.gov／GOV.UK 的規定；量化門檻容易變成新的形式主義 |
| 重要限制可以整批移到查證用的部分，給人讀的部分保持乾淨 | 不採用 | Cochrane 白話摘要指南與英國政府統計指南都明文要求重要限制留在摘要、緊貼它限制的主張，而讀者常只讀摘要。可以後置的只有不影響理解與判斷的細節（見 WS-M09） |
| 「照因果順序一步一條」普遍優於「結論＋理由條列」 | 查無直接證據，不當通則 | 沒有控制相同內容的直接比較，另有敘事不比非敘事好的反例。本地只採為「讀者需要理解與轉述」情境的建議做法（WS-M09），不得寫成有研究支持 |
| 固定方框數上限（例如超過 7 個就拆） | 查無依據，不採用 | 數字出自直覺，常被連帶引用的 7±2 已被視為過度簡化。改用「圖能降低理解成本」與讀者任務判斷 |
| 方框字數上限（例如約 18 字） | 查無依據，不採用 | 沒有來源。方框太長的問題交給渲染驗證與最長區塊抽查 |
| 段落字元門檻（例如主線區塊超過 150 字元就提醒） | 已重開（2026-10-12） | 原判定是未校準前不採用：單行量法會漏掉跨行段落，中文也沒有基準。第七輪由維護者盲讀回饋重開，改為約 120 字的軟提醒，見第七輪紀錄 |
| 證據等級改成節首標一次，取代逐項辨識 | 不採用 | 會把不同強度的主張合併標示。本 skill 採「每個主張都辨識，內容完全相同的標示才共用」 |
| Graphviz 是所有平台的首選 | 不採用 | 選 Graphviz 的理由只在 CodiMD 成立（新舊版同一版 viz.js、Mermaid 新舊版差異大）。GitHub 不畫 graphviz 區塊 |
| 同頁重述一律有害，圖旁的文字說明全刪 | 不採用 | 冗餘效應後續未完整重現（Rop 2018），W3C 建議在伴隨文字中指出複雜圖的重點。只刪沒有額外用途的逐項重述 |
| 標題一律寫結論（文件與章節） | 不採用 | 支持它的研究同時改了內文，效果不能全歸因於標題。好文件實例多用描述性主題標題，GOV.UK 要求描述性、不用問句；結論句標題是投影片慣例。維護者盲讀回饋：金句標題會讓人先跳過 |
| 固定頁數或字數上限（給人讀的部分） | 不採用（WS-M10 撤銷） | 好文件實例沒有通用的一頁共識，有上限的也是把細節移附錄、不砍連接句。盲讀顯示砍半後跳躍、沒頭沒尾。開頭的硬上限（WS-D09）不在此列 |
| 文件開頭固定寫主旨、讀者、用途的聲明 | 查無寫作共識，不採用 | 設計文件慣例寫的是脈絡、範圍、目標與非目標，不是讀者聲明。開頭放什麼由 WS-D09 管 |
| 程式碼位置與敘述固定分開寫 | 查無共識，不採用 | 沒有找到支持的寫作指南或研究 |
| 假設讀者對題目一無所知 | 不採用 | 與專家反轉效應衝突。解釋多深依讀者對題目的熟悉度判斷，研究型產出才預設不熟（WS-D05） |
| 觸發率寫進 SKILL.md 本文 | 不進本文 | 觸發率屬 skill 的維護，不是寫作規則。依官方 skill 撰寫建議，用 plugin eval 量觸發率，列為後續工作 |
| 檔案與行號的寫法（例如 `檔名:行號`）寫成規則 | 只當慣例 | 查無官方規範，同一份文件寫法一致即可 |
| 給下次修改者的寫作契約（隱藏註解記下閱讀任務）寫成規則 | 查無依據，只列選用做法、待驗證 | 寫在 `examples.md`「修改既有文件」，效果驗證前不升為規則 |
| 對話回覆用禁令限制格式（例如「不准用條列」） | 不採用 | Anthropic 提醒為壓格式寫的規則會壓掉需要的結構。改寫成何時用段落、何時用條列 |

## 平台與渲染細節

### 收合

`<details>/<summary>` 收合的相容性（會變動的支援資料指向來源，本檔不寫死版本號）：

- **元素本身的支援不是問題**：支援率與版本現況見 [caniuse](https://caniuse.com/details)（比例會變動，本檔不寫死）。CodiMD／HackMD、GitHub 與多數 IDE 預覽也都支援（HackMD／CodiMD × Chrome／Firefox 有使用者 2026-08-02 實測確認）。
- **Notion**：貼上或匯入 Markdown 時會移除標籤，內容可能整段消失，不會變成 toggle。其 API 另有支援 details/summary，但貼上、匯入、API 是三條不同通路，不能互相外推。確定要貼到 Notion 的文件先展開，改用「存查材料後置＋文末附錄」。
- **頁內搜尋找得到（這是修正過的認知）**：[HTML Standard](https://html.spec.whatwg.org/multipage/interaction.html#interaction-with-details-and-hidden=until-found) 把「頁內搜尋能找到關閉的 `<details>` 並自動展開」列為規範行為；各瀏覽器完成實作的時間不一（caniuse 的 details 條目未涵蓋此行為），目標環境有疑慮就實測。**「收合內容搜不到」對現代瀏覽器的原生 details 已不成立，不能再拿來當收合的否決條件。** Safari 曾有「展開但沒捲到結果」的問題，體驗仍可能不完整。
- **`hidden="until-found"` 是另一套機制**，各家支援狀態的公開資料曾互相矛盾；現況查 [caniuse](https://caniuse.com/mdn-html_global_attributes_hidden_until-found) 或 MDN，目標環境有疑慮就實測。
- **列印**：展開與否沒有一致保證。
- **Jira**：用它自己的展開（expand）元素收合。貼進 Markdown 的 `<details>` 在 Jira 會不會變成收合，未實測（2026-10-16 記）。

### 畫圖平台

寫法以 `diagrams.md` 為準，這裡記查證來源與實測紀錄。

- **CodiMD 內建版本**：2.5.4 是 `mermaid ~8.10.2`，2.6.x 改為 `~11.5.0`，兩版都是 `viz.js ~2.1.2`。來源：[2.5.4 的 package.json](https://raw.githubusercontent.com/hackmdio/codimd/2.5.4/package.json)、[master 的 package.json](https://raw.githubusercontent.com/hackmdio/codimd/master/package.json)。支援的區塊名稱見 [CodiMD 支援語法說明](https://hackmd.io/@codimd/extra-supported-syntax)。
- **HackMD.io** 沒有公開內建版本，不能套 CodiMD 的版本號。
- **GitHub** 畫 `mermaid`、`geojson`、`topojson`、`stl`，不畫 `graphviz`（[GitHub Docs: Creating diagrams](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams)）。
- **為什麼 CodiMD 上的因果圖選 Graphviz**（只在這個平台成立）：文件要貼進 CodiMD，手繪 SVG 貼不進去。改用 Mermaid 後，預設的紫色方框、彎曲連線與壓在線上的標籤讓讀者覺得變醜，調配色後仍無法指定方框位置，也畫不出圖例與圖內標題。Graphviz 在新舊版畫出來一樣，版面最接近手繪，讀者接受。
- **Mermaid 8.10.2 實測會整張解析失敗的寫法**：沒加雙引號又含全形標點的文字、`---` 開頭的 frontmatter、`@{ shape: … }`。兩版都正常的寫法：`flowchart TD`、`:::`、`<br/>`、`『』`、`linkStyle`、`%%` 中文註解、`%%{init}%%`。設定陷阱：init 裡的字串混用單引號，整段設定會被忽略；11.5 會忽略 init 裡的 `curve: linear`。以上來自交接評估以兩版實際渲染的結果（2026-10-11）。
- **中文方框實測**：
  - viz.js 2.1.2 在 Linux 的 Chromium 畫中文方框未超框（交接評估）。
  - 維護者 2026-10-11 在 macOS 把 Graphviz 圖貼進其使用的 CodiMD，初步看過方框未超框。截圖未存檔、CodiMD 版本未確認，正式紀錄待發版前驗證的實際畫面檢查補上。
  - `diagrams.md` 的三張 Graphviz 範例與 Mermaid 範例，2026-10-11 在 macOS 的無頭 Chrome 以 viz.js 2.1.2、Mermaid 8.10.2 與 11.5.0 渲染成功，中文未超框。這是同版引擎的本機渲染，不是 CodiMD 站台本身。
- **未驗證**：CodiMD 認不認 `dot` 區塊名稱（所以規則只寫 `graphviz`）。「`splines=ortho` 處理不了箭頭文字」只出自 Graphviz 文件，沒有實測。

## 句子層細則的證據身分

`examples.md`「句子與條列」節裡「句子的寫法」的六條，證據強度不一，重寫時已依查證結果條件化（這六條原在 `SKILL.md`，重構時移入 `examples.md`）：

| 規則 | 證據身分 | 條件化的內容 |
| --- | --- | --- |
| 段落起手句給方向 | 部分支持 | [Google](https://developers.google.com/style/paragraph-structure) 支持重要資訊放段首，**不支持每段都要表態**。已改成分析論證先給主張、操作步驟先給動作、查閱型先給定義 |
| 有具體事實就不用抽象概括 | 部分支持 | 原措辭「數字與實例是說服力的本體」過度絕對，會誘導補入沒有來源的數字。已加上「前提是那個事實你手上真的有」 |
| 行動型文件收在下一步 | 本地慣例 | 不適用參考手冊、狀態紀錄與純說明文件。已限縮適用範圍 |
| 譬喻節制 | 自創門檻已移除 | 「一篇最多一兩個」查無共識來源。[W3C COGA](https://www.w3.org/TR/coga-usable/) 與 [Google](https://developers.google.com/style/tone) 支持用字面、具體的語言並避免不必要的譬喻，但沒有數量門檻。已改成「只在能承擔解釋功能時用」 |

另外兩條（需要判斷才附理由、校準語言）與 Google 的 procedures 與 tone 指引同向，未做限縮。
