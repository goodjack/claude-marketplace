# Metrics 圖表產生

> 報告涉及基礎設施指標時，附上 CloudWatch 圖表讓讀者一眼看出異常趨勢。使用 AWS `get-metric-widget-image` API 產生 PNG，不需要額外工具。

## 產圖指令

```bash
aws cloudwatch get-metric-widget-image \
  --metric-widget '{...}' \
  --profile {profile} \
  --output text --query MetricWidgetImage \
| base64 --decode > {output_path}
```

`--output text --query MetricWidgetImage` 直接取出 base64 字串，pipe 到 `base64 --decode` 存成 PNG。

## 檔案慣例

| 項目 | 規則 |
|------|------|
| 存放目錄 | `reports/assets/{report-basename}/`（與報告檔名對應） |
| 檔名 | `{service}-{metric}.png`，如 `redis-curritems.png`、`ecs-cpu.png` |
| Markdown 引用 | `![描述](assets/{report-basename}/{filename})` |
| 圖片尺寸 | `width: 800, height: 400` |

範例：報告 `reports/2026-05-07T1500.md` → 圖表存在 `reports/assets/2026-05-07T1500/`：

```markdown
![Redis CurrItems 趨勢](assets/2026-05-07T1500/redis-curritems.png)
```

## 何時產圖

| 情境 | 產圖 |
|------|------|
| T1-5 基礎設施訊號比對：指標異常 | ✅ |
| T5 Redis Memory 調查 | ✅ |
| P1/P2 涉及效能劣化 | ✅ |
| P3 或純 application error | ❌ |
| 指標數值正常（文字帶過即可） | ❌ |

原則：**只為異常指標產圖**。圖表的價值在於讓讀者看到「從正常到異常的轉折」，正常指標不需要附圖佐證。

---

## 圖表模板

所有模板中的 `{placeholder}` 執行前需替換為實際值。時間格式為 ISO 8601 UTC（如 `2026-05-01T00:00:00Z`）。

### Redis：Key 數量 + Memory

```json
{
  "metrics": [
    ["AWS/ElastiCache", "CurrItems", "CacheClusterId", "{node}"],
    [".", "BytesUsedForCache", ".", ".", {"yAxis": "right"}]
  ],
  "title": "Redis Key Count & Memory",
  "period": 300, "stat": "Average",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400,
  "yAxis": {"left": {"label": "Key Count"}, "right": {"label": "Bytes"}}
}
```

### Redis：命令類型（SET vs GET）

```json
{
  "metrics": [
    ["AWS/ElastiCache", "SetTypeCmds", "CacheClusterId", "{node}"],
    [".", "GetTypeCmds", ".", "."]
  ],
  "title": "Redis Commands (SET vs GET)",
  "period": 300, "stat": "Sum",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400
}
```

### Redis：CPU + Network

```json
{
  "metrics": [
    ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", "{node}"],
    [".", "NetworkBytesIn", ".", ".", {"yAxis": "right", "stat": "Sum"}],
    [".", "NetworkBytesOut", ".", ".", {"yAxis": "right", "stat": "Sum"}]
  ],
  "title": "Redis CPU & Network",
  "period": 300, "stat": "Average",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400,
  "yAxis": {"left": {"label": "CPU %", "max": 100}, "right": {"label": "Bytes / 5min"}}
}
```

### ECS：CPU + Memory

```json
{
  "metrics": [
    ["AWS/ECS", "CPUUtilization", "ServiceName", "{service}", "ClusterName", "{cluster}"],
    [".", "MemoryUtilization", ".", ".", ".", "."]
  ],
  "title": "ECS CPU & Memory",
  "period": 300, "stat": "Average",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400,
  "yAxis": {"left": {"label": "%", "max": 100}}
}
```

### ALB：Response Time + 5xx

```json
{
  "metrics": [
    ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "{alb}"],
    [".", "HTTPCode_Target_5XX_Count", ".", ".", {"yAxis": "right", "stat": "Sum"}]
  ],
  "title": "ALB Response Time & 5xx",
  "period": 300, "stat": "Average",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400,
  "yAxis": {"left": {"label": "Seconds"}, "right": {"label": "5xx Count"}}
}
```

### RDS：CPU + Connections

```json
{
  "metrics": [
    ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "{instance}"],
    [".", "DatabaseConnections", ".", ".", {"yAxis": "right"}]
  ],
  "title": "RDS CPU & Connections",
  "period": 300, "stat": "Average",
  "start": "{start_iso}", "end": "{end_iso}",
  "width": 800, "height": 400,
  "yAxis": {"left": {"label": "CPU %", "max": 100}, "right": {"label": "Connections"}}
}
```

---

## 部署標註（Annotations）

調查中找到部署時間點（T1-2）時，在圖表加上垂直標註，讓讀者一眼看出「部署後指標變化」。將 `annotations` 欄位加入任何模板的 JSON 中。

> **注意**：CloudWatch 圖表渲染不支援 CJK 字型，中文標籤會顯示為方塊。annotation label 一律使用英文（如 `03:00 Onset`、`Deploy v2.1`）。

```json
{
  "annotations": {
    "vertical": [
      {"value": "{deploy_time_iso}", "label": "Deploy", "color": "#d62728"}
    ]
  }
}
```

多個事件或門檻值：

```json
{
  "annotations": {
    "vertical": [
      {"value": "{time1}", "label": "Deploy", "color": "#d62728"},
      {"value": "{time2}", "label": "Hotfix", "color": "#2ca02c"}
    ],
    "horizontal": [
      {"value": 80, "label": "Warning 80%", "color": "#ff7f0e", "fill": "above"}
    ]
  }
}
```

---

## Dimension 探索

產圖前需確認正確的 Dimension Value。用 `list-metrics` 探索：

```bash
# Redis node 名稱
aws cloudwatch list-metrics \
  --namespace "AWS/ElastiCache" --metric-name "CurrItems" \
  --profile {profile} --query 'Metrics[].Dimensions' --output json

# ECS service 名稱
aws cloudwatch list-metrics \
  --namespace "AWS/ECS" --metric-name "CPUUtilization" \
  --profile {profile} --query 'Metrics[].Dimensions' --output json

# ALB 名稱
aws cloudwatch list-metrics \
  --namespace "AWS/ApplicationELB" --metric-name "TargetResponseTime" \
  --profile {profile} --query 'Metrics[].Dimensions' --output json
```
