# 資安查案：某個 IP 或某把金鑰有沒有存取我們的 AWS

用途：收到「這個 IP 有沒有打我們」「這把 access key 被誰用了」「有沒有可疑存取」這類線索時的查詢流程。目標是在使用者定好的範圍內，回答「有沒有、打到哪、回了什麼、拿走什麼」，並講清楚每個「查無」有多少證明力。

目錄：
1. 開工前：讀地圖、問範圍
2. 查詢順序
3. 各來源的做法與陷阱（GuardDuty、CloudTrail、WAF、CloudFront、應用程式 log、內網 IP）
4. 公開情資
5. 「0 筆」有沒有證明力
6. 只計數、不讀內容
7. 回報與查完之後

shell、S3 下載、Athena 分區、時區這類跨流程共用的工具陷阱見 `query-basics.md`「執行環境陷阱」，本檔不重複。

---

## 1. 開工前：讀地圖、問範圍

**先讀組織的查案地圖**：`context.local.md` 若指向組織專屬的查案地圖（帳號清單、Athena 表、log bucket、哪些應用程式 log 有記真實來源 IP），先讀完再動手。地圖已經寫明的事不重新探索。

**用一次 AskUserQuestion 問齊三個範圍，每題附建議預設**：

| 範圍 | 建議預設 | 為什麼 |
| --- | --- | --- |
| 時間 | 只查線索出現的那一天（當地時間），換算成 UTC 可能跨兩天 | 範圍每多一天，CloudTrail 與 CloudFront 的量就成倍增加 |
| 帳號與區域 | 線索指向的帳號、主要區域，加上 `us-east-1`（CloudFront、全球 WAF、IAM 等全球服務的事件記在這裡） | 其他帳號與區域等第一輪結果出來再決定 |
| 深度 | 查到「打到哪些路徑、回了什麼狀態碼與大小」為止 | 要確認「拿走了什麼」才往下讀應用程式 log 內容或 CloudTrail 資料事件 |

範圍守則：
- 照使用者定的範圍查。要擴大（多查幾天、同網段、其他帳號）先問，附上為什麼值得擴大；派 subagent 時把範圍原樣交代，不在交代裡自行加碼。
- 「不輕易說沒事」指的是定好的範圍內不下沒有證據的結論，不是無限擴大範圍。
- 範圍內的來源不預先排除：不因為「應該不會在那」就跳過某個來源；沒查的要在回報裡明講。
- 查得到的事實先查掉（有哪些帳號、哪些 Athena 表、log 保留多久、WAF 掛在哪），不拿去問人。
- 資源歸屬不確定（這個 bucket、這台機器是誰的）時，先問使用者或他的主管，不要直接去問平行單位。

---

## 2. 查詢順序

由便宜、涵蓋面廣的來源往細節走。前一步的結果決定下一步要不要做、範圍多大。

| 順序 | 來源 | 回答什麼 | 成本 |
| --- | --- | --- | --- |
| 1 | GuardDuty | AWS 自己有沒有標記這個 IP 或金鑰 | 免費 |
| 2 | CloudTrail | 這個 IP 或金鑰有沒有呼叫 AWS API、呼叫了什麼 | LookupEvents 免費但慢；S3＋Athena 依掃描量計費 |
| 3 | WAF | 外部 HTTP 請求有沒有進到掛了 WAF 的入口、被擋還是放行 | Athena 依掃描量計費 |
| 4 | CloudFront 標準紀錄 | 放行的請求實際回了什麼（狀態碼、大小、網域） | S3 下載或 Athena |
| 5 | 應用程式 log | 打進應用層後做了什麼 | Insights 依掃描量計費 |
| 6 | 公開情資 | 這個 IP 是誰的、名聲如何 | 免費 |

ALB 在 CloudFront 後面時，ALB log 的 `client_ip` 是 CloudFront 節點，拿外部 IP 去查 ALB log 得到 0 筆沒有意義；外部 IP 看 WAF 與 CloudFront。

---

## 3. 各來源的做法與陷阱

### GuardDuty

- 每個區域各自有 detector：`aws guardduty list-detectors --region {region}`。
- 依 IP 過濾可用的條件 key：`service.action.awsApiCallAction.remoteIpDetails.ipAddressV4`、`service.action.networkConnectionAction.remoteIpDetails.ipAddressV4`、`service.action.kubernetesApiCallAction.remoteIpDetails.ipAddressV4`。portProbe 的 IP 不能當過濾條件，要列出後在本機比對。依金鑰過濾用 `resource.accessKeyDetails.accessKeyId`。

```bash
aws guardduty list-findings --detector-id {detector_id} --region {region} --profile {profile} \
  --finding-criteria '{"Criterion":{"service.action.awsApiCallAction.remoteIpDetails.ipAddressV4":{"Equals":["{ip}"]}}}'
```

- GuardDuty 0 筆不等於沒事：它只看自己啟用的資料來源，也不會對每個外部 IP 都產生 finding。
- Security Hub、CloudTrail Lake 可能根本沒開（回 `InvalidAccessException` 或空清單）；這代表「這個來源不存在」，不是「查無」。

### CloudTrail

先搞清楚 trail 長什麼樣再查：`aws cloudtrail describe-trails --region us-east-1`，看是不是組織 trail、log 寫到哪個 bucket、有沒有記資料事件。

- **組織 trail**：bucket 通常在另一個帳號，成員帳號常讀不到（`GetObject`、`GetBucketLocation` 回 AccessDenied）。就算有 Athena 表，也只涵蓋建表時指定的帳號與區域。
- **讀不到 S3 時改用 LookupEvents**：只有管理事件、只回溯 90 天、每個帳號每個區域約 2 TPS、一頁最多 50 筆。一天幾十萬筆要切時段、背景執行、落檢查點，跑之前先估量。
- **LookupEvents 不能依來源 IP 過濾**：查 IP 要整段掃描後在本機比對 `sourceIPAddress`；查金鑰可直接用 `--lookup-attributes AttributeKey=AccessKeyId,AttributeValue={key}`，快很多。
- 分頁用 boto3 paginator，或 CLI 的 `--starting-token` 搭配 `--max-items`；`--no-paginate` 跟 `--starting-token` 不能一起用。
- API 呼叫可能打到任何區域：只掃主要區域會漏，至少把有事件的區域都掃過；全球服務（IAM、CloudFront 等）的事件在 `us-east-1`。
- **資料事件**（S3 `GetObject` 之類）只有 trail 有設定才會記。沒記的話，CloudTrail 回答不了「有沒有拿走 S3 資料」，改看 S3 server access log（若有開）。

### WAF

- 先確認 WAF 掛在哪些資源、logging 開在哪：CloudFront 範圍的 WAF log 在 `us-east-1`，Regional WAF 每區各一份。`aws wafv2 get-logging-configuration` 看有沒有 `LoggingFilter`：有些設定只留 BLOCK，ALLOW 的請求根本不會進 log。
- Athena 欄位：來源 IP 是 `httprequest.clientip`；`timestamp` 是 UTC 毫秒；`httprequest.uri` 不含 query string，參數在 `httprequest.args`。
- 取 Host：`element_at(transform(filter(httprequest.headers, h -> lower(h.name) = 'host'), h -> h.value), 1)`。
- WAF 不記源站回了什麼（ALLOW 的 `responsecodesent` 為空），要知道結果看 CloudFront 紀錄。
- 查前核對表的分區設定與 bucket 生命週期（轉 Glacier 的物件 Athena 會直接略過、不報錯），做法見 `query-basics.md`「執行環境陷阱」的 Athena 段。

```sql
SELECT action, httprequest.uri, count(*) AS n
FROM {waf_table}
WHERE {partition_col} = '{yyyy/mm/dd}'   -- 一定要帶分區條件
  AND httprequest.clientip = '{ip}'
GROUP BY 1, 2 ORDER BY n DESC LIMIT 50
```

### CloudFront 標準紀錄

- 欄位位置、檔名規則、S3 下載流程見 `aws-tools.md`「CloudFront Access Logs」。查案最常用：`c-ip`（第 5 欄）、`sc-status`（第 9 欄）、`sc-bytes`（第 4 欄）、`x-edge-result-type`（第 14 欄，WAF 擋下時為 `Error`）、`x-host-header`（第 16 欄）。
- 沒分區的舊 Athena 表不要直接查（每次都掃全部歷史）；改成只下載線索那幾個小時的檔案在本機比對。
- 檔名的小時是 UTC。少數紀錄會晚送到後面的檔案，查邊界時多抓前後各一小時；當天最近幾小時的檔案可能還沒送到。
- **SPA 對不存在的路徑也回 200**（回首頁 HTML）：判斷「200 是不是真的拿到資料」要比對各路徑的 `sc-bytes`，大小都一樣通常是同一個首頁；再找一個確定不存在的路徑當對照。

### 應用程式 log

**查外部 IP 之前，先探測這個 log 有沒有記真實來源 IP**。只記內網位址或根本沒有 IP 欄位的 log，查不到不代表沒打到。

```
filter @message like /\d+\.\d+\.\d+\.\d+/
| parse @message /(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
| stats count(*) as n by ip
| sort n desc
| limit 20
```

前 20 名全是 `10.`、`172.16-31.`、`192.168.` 開頭，就是只記內網；再跑一次不帶 filter 的 `stats count(*)` 比較「含 IP 的行數」占總量多少。探測結果是組織專屬知識，寫進 `context.local.md` 或它指向的查案地圖。

有記真實 IP 的 log，只計數：

```
filter @message like /203\.0\.113\.5/
| stats count(*) as n by bin(1h)
```

IP 裡的點要跳脫；在 Python 字串裡組查詢用 raw string，否則 Insights 會回 `MalformedQueryException: token recognition error`。

### 線索是內網 IP

不要停在「這是內網 IP」：用 `aws ec2 describe-network-interfaces --filters Name=addresses.private-ip-address,Values={ip}` 在可能的帳號與區域逐一找出是哪個 ENI、掛在哪個服務上；VPC flow log 有開的話再看它連了誰。

---

## 4. 公開情資

| 來源 | 程式讀得到 | 查法 |
| --- | --- | --- |
| RDAP（取代 whois） | 可以 | `curl -sL https://rdap.org/ip/{ip}`，會轉到負責的區域註冊機構；`whois` 在公司網路常卡住 |
| GreyNoise community | 可以（免金鑰，有頻率限制） | `curl -s https://api.greynoise.io/v3/community/{ip}` |
| SANS ISC | 可以 | `curl -s "https://isc.sans.edu/api/ip/{ip}?json"` |
| AlienVault OTX | 可以 | `curl -s https://otx.alienvault.com/api/v1/indicators/IPv4/{ip}/general` |
| ipinfo | 可以 | 國家與 ASN，見 `aws-tools.md`「IP Geolocation」 |
| AbuseIPDB、VirusTotal、Shodan | 通常不行（要金鑰或擋程式存取） | 列出網址請使用者用瀏覽器開 |

情資只說明「這個 IP 是誰、名聲如何」，不能證明有沒有打到我們。

---

## 5. 「0 筆」有沒有證明力

一個來源查無，要以下四點都成立，才能寫成「這個來源可以說明沒有」：

1. **涵蓋**：這個來源真的看得到那個入口（WAF 有掛在那個資源且 ALLOW 有記、trail 涵蓋那個帳號與區域、應用程式 log 有記真實 IP）。
2. **完整**：時間範圍內資料齊全（在保留期限內、沒轉 Glacier、分區對到實際資料夾、CloudFront 檔已送到）。
3. **管線會命中**：拿一個確定存在的值跑同一支查詢當對照組（例如同時段量最大的 IP、自己剛發出的請求、自己的 API 呼叫），要查得到。
4. **沒有吞錯誤**：解壓、下載、查詢的錯誤沒有被 `2>/dev/null` 藏起來（例如 macOS `zcat` 失敗造成的假陰性）。

缺任一點就寫成「這個來源無法判斷」並說明缺哪一點，不寫成「沒有」。

---

## 6. 只計數、不讀內容

- 預設只取計數、時間分布、路徑與狀態碼彙總；log 內文、個資、token 不進對話也不進報告。
- 派 subagent 時明講「只回數字與彙總，不回原始紀錄」。
- 真的要讀內容（例如確認被拿走什麼）先問使用者，讀的時候遮蔽個資與憑證。
- 下載下來的紀錄放暫存目錄，查完刪掉。

---

## 7. 回報與查完之後

回報開頭先講結論：在使用者定的範圍內有沒有、證據多強、哪些地方沒涵蓋。接著每個來源一行：查了什麼範圍、結果、證明力（依第 5 節）。時間一律標時區。

查完把這次撞到的牆寫回去：
- **通用的**（AWS 服務行為、CLI 與 shell 陷阱、判讀方法）：回饋到本 skill 的 references；使用者維護這個 skill 時直接改，否則整理成建議給他。
- **組織專屬的**（帳號、表名、bucket、哪些 log 有記真實 IP、資源歸屬）：寫進 `context.local.md` 或它指向的組織查案地圖。
