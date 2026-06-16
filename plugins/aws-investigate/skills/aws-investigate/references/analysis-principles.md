# 分析判讀原則

## 查詢陷阱：Log 欄位易誤判情境

遇到以下情境時，不要直接用欄位值下結論，需要繞道過濾：

**陷阱 0：CloudWatch `parse` 不會過濾紀錄**

`parse` 只做萃取，**不匹配的紀錄仍保留在結果中**，萃取欄位為空值。在 `stats ... by` 彙總時，所有不匹配的紀錄會被歸入同一個「空值組」，產生一個看起來很大但實際無意義的數字。

解法：在 `parse` 之後加 `| filter {欄位} != ""` 排除未匹配的紀錄，或在 `parse` 之前先 `| filter event like "{關鍵字}"` 縮小範圍。

> **踩坑案例**：Scan 1 第一層查 `occur ERROR`，若沒有先 `filter event like "occur ERROR"`，所有非 occur ERROR 的 error 紀錄也會被計入，第一行出現一個巨大的 count（全部空值欄位的紀錄），容易誤判為「大量解析失敗的 API 錯誤」。

**陷阱 1：SSR 框架 middleware URL 被改寫（Nuxt 3 / H3 特有）**

Nuxt 3 的 H3 框架中，`addServerHandler({ middleware: true })` 掛載的 middleware，H3 在執行時會把 `req.url` 改寫為 `"/"`。pinoHTTP 在 response 完成後才讀 `req.url`，因此所有這類 middleware 的請求都以 `url: "/"` 進 log，**無法用 url 欄位識別是哪個 endpoint**。

解法：改用 `@message like "{應用層識別字串}"` 過濾。識別字串優先選「只有這個 middleware 會產生」的字串。

> **通用原則**：不只 Nuxt 3，許多 SSR 框架的 middleware 都可能在 log 中改寫或遺失 URL 資訊。遇到 `url: "/"` 佔大量 log 時，先確認是否為 middleware 造成的假象。

**陷阱 2：Duration log ≠ 成功 — 某些實作在 status code 判斷前印出**

部分 API caller 或 HTTP middleware 的 duration log 在 status code 判斷邏輯之前就印出（例如在 `finally` block 或 middleware 中記錄），無論成功或失敗都會出現。見到 duration log 不能直接推論「呼叫成功」，需追查：

1. 該 log 的印出位置在 response 解析前還是後（Grep 查具體實作）
2. 查對應的失敗路徑 log（如 `Error`、`Failed to ...`）是否存在
3. 若兩者都不確定，改用 ALB `target_processing_time` 作為執行完成的直接證據

> **提醒**：檢查你的 codebase 中 API caller 的實作。某些框架在 finally/middleware 中記錄請求 duration，會在 response 狀態碼被評估前就執行。不確定時，記下這個發現供未來調查參考。

**陷阱 3：ALB 在 CloudFront 後面時，client_ip 和 WAF country 都不是真實用戶資訊**

常見誤判場景：
- ALB access log 的 `client_ip` → 看到的是 CloudFront edge IP（如 3.172.x、15.158.x、64.252.x），不是用戶 IP
- Regional WAF log 的 `httprequest.country` → 反映 CloudFront edge 所在國家（TW/JP/US/SG），不是用戶國家
- 只有 **CloudFront access log**（`c-ip` 欄位）或 **Global WAF log**（`httprequest.clientIp`）才有真實用戶 IP

判斷 ALB 是否在 CDN 後面的線索：
- ALB log 的 top client_ip 集中在少數 AWS/Apple CIDR（3.172/15.158/64.252/130.176/18.68/52.46）
- `actions_executed` 含 `waf,forward`
- 多個不同 domain 流量打同一個 ALB

解法：見 `aws-tools.md` 的「CloudFront Access Logs」章節。

**陷阱 4：第三方回報「N bytes received」→ 判斷 timeout 位置**

當第三方（如 OIDC provider）回報 timeout 並附上 `N bytes received`，可以推算服務端在 HTTP response 傳送的哪個階段被截斷：

| bytes received | 代表               | 推論                                                                                                   |
| -------------- | ------------------ | ------------------------------------------------------------------------------------------------------ |
| 0              | 完全沒收到任何資料 | 服務端 TCP 連線尚未建立，或 server 完全沒回應                                                              |
| 9              | 收到 `HTTP/1.1 `   | 服務端剛開始送 response header 的瞬間，對方就已 timeout；代表服務端處理時間「剛好」卡在對方的 timeout 邊緣 |
| > 數百 bytes   | 收到部分 header    | 服務端 header 太大，或傳輸太慢                                                                              |

---

## ALB 作為執行完整性的直接證據

當需要確認某個 API 請求是否完整執行（而非被中途截斷或 timeout），ALB log 是比 CloudWatch 應用層 log 更可靠的直接證據：

- **HTTP 200 + target_processing_time** = 該請求從 backend 的角度完整執行並回傳
- **target_processing_time** = backend 實際處理時間（秒），可與 CloudWatch 推算的耗時相互驗證
- HTTP 200 只代表 handler 完整執行並 return，不代表對外呼叫的接收方成功處理——那需要另外查失敗路徑

**使用時機：**
1. CloudWatch log 缺失時，用 ALB 確認整個 endpoint 有無完成
2. 懷疑某個 webhook / 長時間 API 有沒有在 timeout 前完成
3. 驗證 `asyncio.gather()` 等平行操作是否全部完成

---

## 流量 Spike 分析方法

當調查「流量突然增加」或「特定國家 IP 暴增」時，比較 spike 和 normal 時段的**集中度**比單純看國家/IP 分布更有意義：

| 指標 | 計算方式 | 意義 |
| --- | --- | --- |
| **Requests/IP ratio** | total_requests ÷ unique_IPs | 集中度——數字越高代表越少 IP 打越多 request |
| Country 佔比變化 | spike 期間 vs 正常期間的國家比例 | 是「新來源出現」還是「既有流量放大」 |
| Unique IPs 數量 | 兩個時段的獨立 IP 數比較 | 新 IP 暴增 = 真正的新流量；IP 減少但 reqs 增加 = 密集請求 |

**判讀邏輯：**

| Spike 特徵 | reqs/IP ratio | unique IPs | 可能原因 |
| --- | --- | --- | --- |
| 新流量湧入 | 不變 | 暴增 | 行銷活動、社群分享、搜尋引擎索引 |
| 少數 IP 密集請求 | 暴增 | 減少或不變 | Bot/scraper、aggressive polling、API abuse |
| 整體放大 | 不變 | 微增 | 正常尖峰（如午休時段）、活動頁面效應 |

**操作流程（用 CF log 或 ALB log）：**
1. 用 `awk + sort + uniq -c` 算出 spike 和 normal 各自的 reqs/IP ratio
2. 若 ratio 異常高：取 top IPs → `ipinfo.io` batch 確認來源
3. 比較兩時段的 top paths 分布——是否打相同端點（正常瀏覽）或特定路徑（爬蟲/攻擊）

---

## 效能問題判讀

**看 p50 vs p95 差距判斷 root cause 類型：**

| p50 vs p95                 | 代表             | 典型原因                                                            |
| -------------------------- | ---------------- | ------------------------------------------------------------------- |
| p50 ≈ p95（差距 < 10%）    | 延遲來自固定成本 | 序列操作、固定 network hop 數、**底層驅動行為變更**（如 KEYS→SCAN） |
| p50 << p95（p95 明顯更高） | 延遲來自隨機事件 | 網路抖動、DB lock、GC pause、冷啟動                                 |

> **注意**：p50 ≈ p95 有多種可能的 root cause。不要看到程式碼有 `for + await` 就認定是序列執行造成的。如果問題有明確的起始時間點（而非「一直都這樣」），優先追查「那個時間點改了什麼」（回到 T1）。

**底層驅動行為變更的辨識方式：**

dependency 升版可能在不改應用程式碼的情況下改變底層行為。特徵是：有明確的起始時間點、多個不相關的 endpoint 同時受影響、基礎設施指標同步異常。確認方式：比對 lockfile diff → 查 changelog / PR → 用 CloudWatch Metrics 驗證。

---

## 數據點附查詢來源

報告中每個數據聲明都要附上可重現的查詢來源編號（`[Q1]`、`[ALB-Q1]`），讓讀者無需找人就能自行驗證。

| 情境                         | 是否附查詢       |
| ---------------------------- | ---------------- |
| 具體數字（次數、比例、耗時） | **必附**         |
| 時序分析（哪個時間點爆發）   | **必附**         |
| 「我們觀察到...」等歸納句    | **必附**         |
| 程式碼行為推論（不來自 log） | 附程式碼位置即可 |
| 背景說明段落                 | 不需要           |

報告末尾的「附錄：查詢指令」章節，每個 Qn 包含：查詢描述、Log Group / Athena Table、完整 CLI 執行指令、結果解讀說明。

---

## 驗證守則

- **查證而非猜測**：用 Grep / Read 驗證程式碼路徑和呼叫鏈，能查證的必須查證
- **量化而非模糊**：提供具體錯誤數量、影響範圍、佔比，避免「需要確認」等模糊表述
- **誠實標示**：明確區分已驗證的問題、經驗推測、需進一步確認的項目
- **區分訊號與雜訊**：明確分離真正的業務問題和外部流量造成的錯誤
- **語言精準**：資料有混合結果時用限定語。例如「大量 request 無 cookie（6,852/10,506 筆）」而非「不帶 cookie」；「經過 Nuxt server 的回應無法被 CDN cache」而非「CDN 完全無法 cache」。絕對語句只在資料 100% 支持時使用
- **觀測層區分**：後端 application log、CDN access log、ALB access log 是不同觀測層，看到的 error / 404 代表不同意義。報告中不要混在同一行呈現，要標明來源層。例如「後端 log: UUID not found on /services/info」和「CloudFront: 404 集中在使用者詳情子頁」是不同層的觀察
- **數字可信度**：引用查詢結果時，確認數字沒有被 context 壓縮搞亂或憑空產生。無法驗證的具體數字（如百分比、倍數）寧可不用，也不要寫一個可能不對的數字
- **用 `stats count()` 做伺服器端彙總**：避免拉回大量原始 log 浪費 token
- **只在需要看具體錯誤細節時才 `limit 1~5` 取樣本**，搭配 `python3 -c` 解析 JSON
- **確認每個 log group 的實際 tech stack** — 名稱可能誤導（如名稱暗示後台管理的 log group 實際上可能是 SSR 前端，勿套用 Python backend 的查詢語法）
- **敏感資訊**（client_secret、Authorization token）在 log 中可能未完全遮蔽，注意不要洩漏

---

## 間接確認成功：查失敗路徑是否存在

當某個操作沒有明確的「成功」log 可查，可以用「反向查失敗路徑」策略間接確認：

1. 找出該操作所有可能的失敗路徑（通常是 try/except 的各種 catch）
2. 確認每條失敗路徑對應的 error log 關鍵字
3. 查詢這些關鍵字在目標時間段內是否出現

若所有失敗路徑均無 error log，結合 duration log 確認呼叫發出，可高度確信操作成功。最終仍以 ALB HTTP 狀態碼作為最強確認依據。

---

## 報告寫作風格

報告的目的是讓讀者快速吸收和行動，不是展現調查的深度。以下原則適用於所有報告類型。

### 表達形式優先序（基於 NNG 掃描閱讀研究 + Cognitive Load Theory）

結構化格式降低 extraneous cognitive load（讀者花在解碼排版的認知資源），讓讀者專注於理解內容本身。

1. **表格**——適合多屬性的結構化比較（根因分析、排除假設、Action Items、角色重點）
2. **條列（bullet points）**——適合事件描述、觀察列舉（發生什麼事）
3. **段落**——只用於需要上下文連貫的敘事（流程面根因等少數情境）

### 語氣光譜（基於 Google / Microsoft Style Guide + Blameless Postmortem 文化）

語氣定位為 **Knowledgeable Friend**（Google Style Guide）：像懂技術的同事在說明狀況，不僵硬也不輕挑。

| 太正式 ❌ | 太口語 ❌ | 目標 ✅ |
| --- | --- | --- |
| 「使用者面向影響有限」 | 「平常使用無感」 | 「一般使用者不會感覺到異常」 |
| 「緊急處置手動清除所有 session 後」 | 「清掉所有 session」 | 「清除 Redis 後」 |
| 「流程面根因」 | 「為啥沒早點抓到」 | 「為什麼沒有更早發現」 |
| 「該因素之影響」 | 「它幹了什麼」 | 「影響」 |

### 精簡校準

- **Orwell's Third Rule**（「If it is possible to cut a word out, always cut it out」）：每句話都要有存在的理由
- **Einstein Principle**（「As simple as possible, but not simpler」→ 寫作版：As concise as possible, but as wordy as necessary）：如果多幾個字能避免讀者猜測，那幾個字不是贅字
- **DRY（Don't Repeat Yourself）**：同一個 fact 只出現在一個 section。事件時序裡寫過的事實，不在其他 section 重述

### 模板彈性（Flexible Template）

- **「Only Include Relevant」**（Google SRE 精神）：模板是鷹架而非監獄。若某個 section（例如「各角色重點」或「排除的假設」）對這次事件不適用，請直接省略該區塊，**不要**填入「無」或湊字數。
