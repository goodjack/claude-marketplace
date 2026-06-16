# 已知系統行為模式

> 此檔案包含**跨組織通用、廣泛適用的行為模式**，來自 AWS 託管 Web 應用的調查經驗。
> 專案特定的知識由 AI 維護在 skill 根目錄的 `context.local.md`（Phase 0 載入）。
>
> 遇到 log / ALB 紀錄符合以下模式時，先比對此表和 `context.local.md` 決定是雜訊、正常行為還是值得追蹤的問題，避免每次重複調查。
>
> **維護原則**：若報告中發現「已知行為」已被修復，行動清單加入：`[維護] 更新 context.local.md：標記 {pattern} 為 [已修復 YYYY-MM]`

---

## 安全掃描 / 攻擊流量（跨 stack 通用）

| 模式 | 影響範圍 | 判斷 | 說明 | 常見起始 |
| --- | --- | --- | --- | --- |
| Path traversal（`%c0%af..`、`../etc/passwd`） | 前端 ALB + CloudWatch | 攻擊雜訊 | 可能是委託的安全掃描或外部攻擊；HeadlessChrome User-Agent 是常見指標 | 常態 |
| 整數溢位（`18446744073709551617`、`4294967297`） | 前端 + 後端 500 | 攻擊雜訊，但暴露驗證缺口 | 後端應回 422 而非 500——這是真正的防禦弱點 | 常態 |
| AppScan header 注入（`\r\nAppScanHeader:`） | 後端 exception | 攻擊雜訊 | IBM AppScan 安全掃描器特徵；注入在 request body 的字串欄位 | 常態 |
| 隨機短字串 fuzzing | 後端 exception / 驗證錯誤 | 攻擊雜訊 | 搜尋和輸入欄位被填入隨機值；少量可能是真實使用者亂打 | 常態 |
| 同 IP 短時間打多個 endpoint | ALB + CloudWatch | 掃描行為 | 用 ALB `client_ip` 彙總確認 | 常態 |

> **注意**：即使確認是掃描流量，暴露的輸入驗證缺口（如極端整數值造成 500 而非 422）仍應記錄在報告的「安全觀察」section。

---

## ALB Status Code 判讀（通用）

| Status | 模式 | 判斷 | 說明 |
| --- | --- | --- | --- |
| `419` | POST 任何路徑 | 正常防護，觀察量 | CSRF 保護觸發——通常是爬蟲或外部工具未帶 CSRF token |
| `401` | 需認證的 endpoint | 正常行為 | 未登入使用者存取受保護資源；量暴增才需調查 |
| `460` | SSE / long-polling / webhook endpoint | 正常行為 | 連線中斷（使用者切頁、關 tab）——不是伺服器錯誤 |
| `460` | OIDC / auth callback endpoint | 需關注 | Auth provider 觸發 callback 但 handler 太慢，provider 超時放棄；可能導致 session 不一致 |
| `404` | `favicon.ico`、`/.env`、`/index.php`、`/wp-*` | 雜訊 | 外部爬蟲 / 掃描工具自動探測，非真實使用者 |
| `502` + `target_status_code = '-'` | 任何路徑 | 需調查 | Container 完全無回應，疑似 OOM crash；圖檔處理路徑特別容易觸發 |
| `504` | `target_processing_time = -1` | 需調查 | ALB 60s timeout；確認該 endpoint 是否有已知慢操作（無 timeout 的外部 API 呼叫、blocking 的 gather 操作） |

---

## 爬蟲行為識別（通用）

| 訊號 | 識別方法 |
| --- | --- |
| 同一 ID 打固定路徑組合 | 查詢：`stats count() as total_hits, count_distinct(full_path) as unique_paths by id` — 每個 ID 的 unique_paths 一致 = 爬蟲 |
| HeadlessChrome User-Agent | ALB UA 欄位檢查 |
| 每次請求都不帶 cookie | 結合 session key 成長分析 |
| 系統性請求模式 | 請求時間固定間隔、路徑依序列舉 |

---

## Redis / 快取異常模式（通用）

| 特徵 | 影響範圍 | 判斷 | 說明 |
| --- | --- | --- | --- |
| CurrItems 線性成長 + SET 命令數只微增 | Redis memory | **Session 汙染** | 大量 unique key 被建立但 SET 命令率只微增 = 每個 SET 都建新 key。通常是 bot 不帶 cookie 觸發 `saveUninitialized: true` 的 session 機制 |
| Bot 流量高 + CurrItems 線性成長 + session prefix 占大宗 | 前端 ALB + 後端 ALB + Redis | **Bot session 汙染** | 搜尋引擎 bot 或 AI 索引 bot 不維持 cookie，每次請求建新 session。辨識：ALB UA 分析、reverse DNS 反查確認 bot 身分 |
| Redis DatabaseMemoryUsagePercentage 持續爬升但 EngineCPU 平穩 | Redis memory | 需調查 key 來源 | Memory 成長但 CPU 不高 = 大量小 key 累積（session、cache），不是大 value 或複雜命令。先查 CurrItems 確認 key 數成長，再比對 SetTypeCmds 判斷來源 |
| CurrItems 穩定 + BytesUsedForCache 暴增 | Redis memory | **大 value key** | key 數少但存了很大的 JSON payload。用 `redis-cli --bigkeys` 找出 |
| CurrItems 成長 + Evictions > 0 | Redis memory | Redis 觸發 LRU 淘汰但追不上 | 確認 `maxmemory-policy` 設定 |

---

## 流量 Spike 判讀（通用）

| 模式 | 特徵 | 判斷 | 下一步 |
| --- | --- | --- | --- |
| 正常尖峰 | reqs/IP ratio 不變、打一般頁面端點、ECS/ALB 指標正常 | 正常行為 | 確認 auto-scaling 正確觸發即可 |
| 少數 IP 集中轟 | reqs/IP ratio 暴增（如 2x+）、unique IPs 反而減少 | 需判斷意圖 | 取 top IPs → geolocation → 看 UA 和 path pattern |
| Bot/crawler burst | 大量 unique URLs + 301/403 status + 固定 IP 段 | Bot 行為 | 確認是否造成 session 汙染（Redis CurrItems）或 CPU 壓力 |
| CDN 背後辨識困難 | ALB client_ip 全是 CDN edge IP、無法直接看來源國家 | 架構限制 | 改查 CloudFront access log 或 Global WAF log 取真實 IP |

> **常見誤判**：PM/GA 回報「某國 IP 暴增」但 ALB/WAF 層看不到——通常是因為 ALB 在 CDN 後面。見 `analysis-principles.md` 陷阱 3。

---

## 相依性升版行為變化（通用）

| 訊號 | 模式 | 範例 |
| --- | --- | --- |
| 明確起始時間點 + 多個不相關 endpoint 同時受影響 | 共用相依性改變行為 | Storage driver 從 `KEYS`（一次 roundtrip）改為 `SCAN`（多次 roundtrip 迭代整個 keyspace），導致 roundtrip 爆增 |
| 基礎設施指標同步異常 | 底層 driver 行為改變 | Redis `EngineCPUUtilization` 和 `NetworkBytesIn/Out` 在部署後同步衝高 |
| 應用程式碼沒改但行為不同 | transitive dependency 升版 | Lockfile diff 顯示核心相依的 major version 跳版，但應用程式碼本身沒有改動 |

**辨識方式**：比對 lockfile diff（`pnpm-lock.yaml`、`package-lock.json`、`poetry.lock`）→ 查 changelog/PR 確認行為變化 → 用 CloudWatch Metrics 驗證。
