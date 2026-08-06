# AWS 診斷工具速查

> 以下列出分析時可用的 AWS 工具。不需要每次都全用，依問題性質自行判斷。列出目的是避免「一頭熱查 log 忘記還有其他訊號來源」。

## CloudWatch Logs Insights

應用層 log 查詢（error、warn、trace 追蹤）。詳見 `references/periodic-scan.md` 與 `references/investigation-toolkit.md`。

## ALB Access Logs（Athena）

網路層事實（container crash、gateway timeout、非預期狀態碼）。詳見 `references/periodic-scan.md` Scan 4。

## CloudWatch Metrics

基礎設施指標的時序比對。先用 `aws cloudwatch list-metrics --namespace "{ns}"` 探索可用資源，再用 `get-metric-statistics` 拉指標做部署前後比對。異常指標可用 `get-metric-widget-image` 產生 PNG 圖表附在報告中（模板與慣例見 `references/metrics-charts.md`）。

| 服務         | Namespace            | 關鍵指標                                                               | 異常判斷                     |
| ------------ | -------------------- | ---------------------------------------------------------------------- | ---------------------------- |
| Redis        | `AWS/ElastiCache`    | `EngineCPUUtilization`, `NetworkBytesIn/Out`, `CurrConnections`        | 部署前後突然衝高             |
| Redis memory | `AWS/ElastiCache`    | `CurrItems`, `DatabaseMemoryUsagePercentage`, `BytesUsedForCache`      | key 數線性成長 = session/cache 汙染 |
| Redis 命令級 | `AWS/ElastiCache`    | `SetTypeCmds`, `GetTypeCmds`, `CacheHitRate`, `Evictions`              | SET 暴增或 key 累積導致 memory 滿 |
| Redis 命令延遲 | `AWS/ElastiCache`  | `*CmdsLatency`（`SetTypeCmdsLatency`、`GetTypeCmdsLatency` 等）        | 命令次數沒變但延遲衝高＝單一命令變慢，與上一列的次數指標對照看 |
| ECS          | `AWS/ECS`            | `CPUUtilization`, `MemoryUtilization`                                  | OOM 或 CPU throttle          |
| ALB          | `AWS/ApplicationELB` | `TargetResponseTime`, `HTTPCode_Target_5XX_Count`                      | 延遲突升、5xx 突增           |
| RDS          | `AWS/RDS`            | `CPUUtilization`, `DatabaseConnections`, `ReadLatency`, `WriteLatency` | 連線池耗盡、慢查詢           |

> **已知案例：相依性升版改變 driver 行為**：Storage library 升版後將 Redis driver 的 `getKeys` 從 `KEYS`（一次 roundtrip）改為 `SCAN`（多次 roundtrip 迭代整個 keyspace）。即使 SCAN 帶了 `MATCH pattern`，Redis 仍需掃描所有 key 再做過濾，導致 roundtrip 數量暴增。症狀：Redis `EngineCPUUtilization` 和 `NetworkBytesIn/Out` 同步衝高，所有使用 `storage.getKeys()` 的 endpoint 同時變慢。

> **已知案例：Bot 流量 + session 汙染**：Bot 大量爬取 + 前端 session `saveUninitialized: true`，導致每個 bot request 在 Redis 建新 session key。數小時內 CurrItems 線性成長數倍。關鍵判斷指標：CurrItems 線性成長 + SetTypeCmds 只微增 = 每個 SET 都是新 key。追查路徑：ALB UA 分析確認 bot 來源 → Redis CurrItems 確認 key 累積 → 前端 session module 確認 `saveUninitialized` 機制。

## CloudFront Access Logs

當 ALB 在 CloudFront 後面時，ALB `client_ip` 是 CDN edge IP，不是真實用戶 IP。需要查 CloudFront access log 取得真實來源。

**查詢路徑（依可用性選擇）：**

| 方式 | 條件 | 速度 |
| --- | --- | --- |
| CloudFront Athena table | 已建好 table（如 `{service}_cloudfront_logs`） | 快（SQL 查詢） |
| S3 直接下載 | CF logging 有開但無 Athena table | 慢（下載 + 本地解析） |
| Global WAF log | CloudFront 層有掛 WAF 且 logging 有開 | 快（有 country 欄位） |

**CloudFront standard log 格式（tab-separated）：**
- Field 5: `c-ip`（真實用戶 IP）
- Field 20: `x-forwarded-for`
- 無 country 欄位——需配合 geolocation 工具

**S3 直接下載流程（無 Athena table 時）：**

```bash
# 1. 找到 CF distribution 的 log bucket
aws cloudfront get-distribution --id {dist_id} --profile {profile} --output json \
  | python3 -c "import json,sys; c=json.load(sys.stdin)['Distribution']['DistributionConfig']['Logging']; print(f'Bucket: {c[\"Bucket\"]}\nPrefix: {c[\"Prefix\"]}\nEnabled: {c[\"Enabled\"]}')"

# 2. 列出目標時段的 log 檔（檔名含 UTC hour）
aws s3 ls "s3://{bucket}/{prefix}/{dist_id}.{YYYY-MM-DD}-{HH}" --profile {profile}

# 3. 下載 + 解壓 + 分析 c-ip
aws s3 cp "s3://{bucket}/{prefix}/{file}.gz" /tmp/cf.gz --profile {profile}
gunzip -f /tmp/cf.gz
tail -n +3 /tmp/cf | awk -F'\t' '{print $5}' | sort | uniq -c | sort -rn | head -20
```

**IP Geolocation（batch 確認國家）：**

`ipinfo.io` 免費額度 50K/月，單筆查詢無需 API key：

```bash
curl -s "https://ipinfo.io/{ip}/country"    # 回傳 2-letter country code
curl -s "https://ipinfo.io/{ip}/json"       # 完整資訊（country, org, city）
```

比 `whois` 快 10 倍以上，適合 batch loop 50-100 筆快速分類。

## CloudWatch Alarms

確認問題時段是否有既有 alarm 被觸發，避免重複調查已知問題。用 `aws cloudwatch describe-alarm-history --start-date --end-date --history-item-type StateUpdate` 查詢。

## ECS 容器診斷

確認 ALB 502 / `target_status_code = '-'` 的真正原因（OOM kill、health check 失敗、deployment 滾動更新等）。

- **停止原因**：`aws ecs list-tasks --desired-status STOPPED` → `aws ecs describe-tasks` → 看 `stoppedReason`、`stopCode`、`containers[].reason`
- **部署狀態**：`aws ecs describe-services` → 看 `deployments[]` 的 `status`、`createdAt`、`rolloutState`
- **即時診斷**：`aws ecs execute-command --interactive --command "/bin/sh"` 進入 running container

## CodePipeline

確認部署流水線的執行時間與狀態，用於 T1 的部署事件交叉比對。`aws codepipeline list-pipeline-executions --pipeline-name {name}` → `get-pipeline-execution` 看各 stage 時間。

## RDS

DB 層效能問題（慢查詢、連線池耗盡）。除了 CloudWatch Metrics，若有開啟 Performance Insights 可用 `aws pi get-resource-metrics` 查 top SQL 和等待事件。
