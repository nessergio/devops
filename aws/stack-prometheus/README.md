# Prometheus Monitoring Stack

## Metrics-Driven Auto-Scaling Without Kubernetes

This directory contains the complete observability and auto-scaling stack that **replaces Kubernetes auto-scaling** with a simpler, more flexible approach.

## Overview: Beyond Kubernetes Metrics

This demonstrates that you can achieve **better auto-scaling than Kubernetes** without the complexity:

### What This Replaces

| Kubernetes Component | This Project Uses | Why It's Better |
|---------------------|-------------------|-----------------|
| metrics-server | Prometheus | More powerful, any metric type |
| HorizontalPodAutoscaler | Custom Prometheus alerts + Webhooks | Scale on ANY metric, not just CPU/memory |
| Cluster Autoscaler | Prometheus + AWS Auto Scaling API | Native AWS integration, simpler |
| K8s Custom Metrics API | Direct Prometheus queries | No API adapter complexity |
| K8s Event-based Autoscaler (KEDA) | AlertManager webhooks | Simpler, no extra controllers |

### The Stack

The Prometheus stack provides comprehensive monitoring and auto-scaling for the infrastructure:

- **Prometheus**: Metrics collection, storage, and alert evaluation - *more powerful than K8s metrics-server*
- **Grafana**: Visualization dashboards - *better than K8s Dashboard*
- **AlertManager**: Alert routing and notification - *more flexible than K8s events*
- **wh (Webhook Handler)**: Automated scaling actions - *replaces K8s HPA + Cluster Autoscaler*
- **node-exporter**: System metrics for the Prometheus instance itself

**Key Advantage**: Scale on **any business metric** (request rate, error rate, custom metrics), not limited to CPU/memory like basic K8s HPA

## Architecture: Intelligent Auto-Scaling

This architecture is **more flexible than Kubernetes HPA** because:
1. Can scale on ANY metric (not just CPU/memory)
2. Custom scaling logic (not limited to K8s scheduler)
3. Multi-level scaling (containers AND instances)
4. Faster decisions (no K8s API server latency)

```
Worker Instances → Prometheus (EC2 Service Discovery)
                       ↓
                  Alert Rules (ANY metric!)
                       ↓
                  AlertManager
                       ↓
        ┌──────────────┴──────────────┐
        ↓                             ↓
   Telegram                    Webhook (wh)
  (Notifications)                     ↓
                              AWS API (SSM/AutoScaling)
                                     ↓
                         Scale Containers/Instances
```

**vs. Kubernetes**:
- K8s: metrics-server → HPA controller → scale replicas
- This: Prometheus → AlertManager → custom webhook → scale anything

**Advantages**:
- ✅ Scale on request rate, error rate, latency, custom business metrics
- ✅ Custom scaling logic (e.g., scale different instances differently)
- ✅ Multi-cloud capable (not K8s-specific)
- ✅ Simpler debugging (logs vs. K8s controller traces)

## Files

```
stack-prometheus/
├── docker-compose.yml      # Service definitions
├── prometheus.yml          # Prometheus configuration
├── alertmanager.yml        # AlertManager routing rules
├── rules.yml              # Prometheus alert rules
├── nginxlogsexp.yml       # Nginx logs exporter config
├── start.sh               # Deployment startup script
├── scaletest.sh           # Manual alert injection for testing
├── dashboards/            # Grafana dashboard definitions
│   ├── dashboards.yaml    # Dashboard provider config
│   ├── demo.json          # Main application dashboard
│   ├── nginx.json         # Nginx metrics dashboard
│   └── nodes.json         # Node/system metrics dashboard
└── datasources/           # Grafana datasource configuration
    └── datasources.yaml   # Prometheus datasource
```

## Services

### Prometheus

**Purpose**: Time-series database, metrics collection, and alert evaluation

**Configuration**:
- Image: prom/prometheus:latest
- Ports: 9090 (web UI and API)
- Volumes:
  - ./prometheus.yml → /etc/prometheus/prometheus.yml
  - ./rules.yml → /etc/prometheus/rules.yml
  - prometheus-data → /prometheus (persistent storage)

**Key Features**:
- EC2 service discovery (auto-detects worker instances)
- 15-second scrape interval
- 7-day data retention
- Custom alert rules for auto-scaling

**Web UI Access**:
- Direct: http://[prometheus-instance-ip]:9090
- Via Load Balancer: http://[nlb-dns]/prometheus/

**Configuration File**: prometheus.yml

### Grafana

**Purpose**: Metrics visualization and dashboards

**Configuration**:
- Image: grafana/grafana:latest
- Port: 3000 (web UI)
- Volumes:
  - ./dashboards → /etc/grafana/provisioning/dashboards
  - ./datasources → /etc/grafana/provisioning/datasources
  - grafana-data → /var/lib/grafana (persistent storage)

**Default Credentials**:
- Username: admin
- Password: 12341234 (**SECURITY WARNING: Change this password in production!**)

**Web UI Access**:
- Direct: http://[prometheus-instance-ip]:3000
- Via Load Balancer: http://[nlb-dns]/grafana/

**Pre-configured Dashboards**:
1. Demo Dashboard (demo.json)
2. Nginx Dashboard (nginx.json)
3. Nodes Dashboard (nodes.json)

### AlertManager

**Purpose**: Alert routing, grouping, and notification

**Configuration**:
- Image: prom/alertmanager:latest
- Ports: 9093 (web UI and API)
- Volume: ./alertmanager.yml → /etc/alertmanager/alertmanager.yml

**Notification Channels**:
1. **Telegram**: For critical alerts (instance down, errors)
2. **Webhook (wh)**: For auto-scaling alerts

**Web UI**: http://[prometheus-instance-ip]:9093

**Configuration File**: alertmanager.yml

### wh (Webhook Handler)

**Purpose**: Receive alerts and execute automated scaling actions

**Configuration**:
- Image: Built from ../wh directory
- Port: 9999 (webhook endpoint)
- Environment:
  - `AWS_REGION`: AWS region for API calls
  - Instance credentials via IAM role

**Capabilities**:
- **container-up/down**: Scale service-a containers via SSM
- **worker-up/down**: Scale ASG instances via Auto Scaling API

**Webhook Endpoint**: http://localhost:9999/webhook

### node-exporter

**Purpose**: Export system metrics for the Prometheus instance itself

**Configuration**:
- Image: prom/node-exporter:latest
- Port: 9100 (metrics endpoint)
- Volumes: Host filesystem mounts (read-only)

**Metrics**: CPU, memory, disk, network for Prometheus instance

## Configuration

### Prometheus Configuration (prometheus.yml)

**Key Settings**:

```yaml
global:
  scrape_interval: 15s      # Scrape every 15 seconds
  evaluation_interval: 15s  # Evaluate rules every 15 seconds

# Alert rules
rule_files:
  - /etc/prometheus/rules.yml

# AlertManager integration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Prometheus instance system metrics
  - job_name: 'prometheus-node'
    static_configs:
      - targets: ['node-exporter:9100']

  # Worker instances (EC2 service discovery)
  - job_name: 'workers'
    ec2_sd_configs:
      - region: eu-central-1
        port: 8080
        filters:
          - name: tag:worker
            values: ['true']
    relabel_configs:
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance_id
      - source_labels: [__meta_ec2_private_ip]
        target_label: instance
```

**EC2 Service Discovery**:
- Automatically discovers instances with tag `worker=true`
- Scrapes port 8080 (exporter-merger endpoint)
- Adds instance_id and private IP as labels

### Alert Rules (rules.yml)

This is where the **magic happens** - these simple rules replace complex Kubernetes HPA configurations:

**Why This Is Better Than K8s HPA**:

| Feature | Kubernetes HPA | This Project (Prometheus Alerts) |
|---------|---------------|----------------------------------|
| Metrics | CPU/Memory (basic), Custom Metrics (complex) | **ANY Prometheus metric** |
| Configuration | K8s HPA YAML + metrics adapters | Simple Prometheus alert rules |
| Scaling Logic | Fixed formula (target utilization) | **Flexible conditions** (PromQL) |
| Multi-metric | Requires multiple HPAs | Single alert with complex query |
| Debugging | kubectl describe hpa | Read alert rules, check Prometheus UI |

**Example Comparison**:

Kubernetes HPA (CPU-based):
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: service-a
spec:
  scaleTargetRef:
    kind: Deployment
    name: service-a
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

This Project (Request-rate based):
```yaml
- alert: HighRequestRate
  expr: rate(nginx_http_response_count_total[5m]) / count(up) > 50
  for: 5m
  labels:
    doaction: "true"
    action: container-up
```

**Much simpler** and can scale on **business metrics**!

---

**Critical Alerts** (notify + auto-scale):

1. **InstanceDown**:
   - Condition: Instance unreachable for >1 minute
   - Severity: critical
   - Action: Telegram notification
   - *K8s equivalent: Node NotReady*

2. **InstanceFault**:
   - Condition: 5+ 4xx errors in 5 minutes
   - Severity: critical
   - Action: Telegram notification
   - *K8s doesn't have this - requires custom metrics!*

3. **HighRequestRate**:
   - Condition: >50 requests/container in 5 minutes
   - Severity: critical
   - Action: Webhook → Scale containers up
   - Label: `doaction=true`, `action=container-up`
   - *K8s equivalent: HPA on custom request rate metric (complex setup)*

4. **LowRequestRate**:
   - Condition: ≤1 request/container in 5 minutes
   - Severity: critical
   - Action: Webhook → Scale containers down
   - Label: `doaction=true`, `action=container-down`
   - *K8s HPA doesn't scale down based on low traffic easily*

5. **HighCPU**:
   - Condition: >50% CPU for 5 minutes
   - Severity: critical
   - Action: Webhook → Scale instances up
   - Label: `doaction=true`, `action=worker-up`
   - *K8s equivalent: Cluster Autoscaler (complex, slow)*

6. **LowCPU**:
   - Condition: ≤1% CPU for 5 minutes
   - Severity: critical
   - Action: Webhook → Scale instances down
   - Label: `doaction=true`, `action=worker-down`
   - *K8s Cluster Autoscaler takes 10+ minutes to scale down*

**Warning Alerts**:

1. **HighRequestLatency**:
   - Condition: 90th percentile >1 second
   - Severity: warning
   - Action: Telegram notification only
   - *K8s: Would require custom metrics API setup*

**Alert Rule Example**:

```yaml
groups:
  - name: scaling
    interval: 15s
    rules:
      - alert: HighRequestRate
        expr: rate(nginx_http_response_count_total[5m]) /
              (count(up{job="workers"} == 1) or vector(1)) > 50
        for: 5m
        labels:
          severity: critical
          doaction: "true"
          action: container-up
        annotations:
          summary: "High request rate detected"
          description: "Request rate is {{ $value }} req/s per container"
```

### AlertManager Configuration (alertmanager.yml)

**Route Configuration**:

```yaml
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'telegram'
  routes:
    # Auto-scaling alerts to webhook
    - match:
        doaction: "true"
      receiver: 'webhook'
      group_wait: 5s
      group_interval: 5s
      repeat_interval: 5m

receivers:
  # Telegram notifications
  - name: 'telegram'
    telegram_configs:
      - bot_token: 'YOUR_BOT_TOKEN'
        chat_id: 365473701
        parse_mode: 'HTML'

  # Webhook for auto-scaling
  - name: 'webhook'
    webhook_configs:
      - url: 'http://wh:9999/webhook'
        send_resolved: false
```

**Customization**:
- Replace `YOUR_BOT_TOKEN` with your Telegram bot token
- Change `chat_id` to your Telegram chat ID
- Adjust timing parameters as needed

### Grafana Dashboards

**Demo Dashboard** (dashboards/demo.json):
- Response time (90% quantile)
- Requests per second
- HTTP status codes distribution
- Total HTTP traffic
- Active service-a containers

**Nginx Dashboard** (dashboards/nginx.json):
- Active connections
- Connection accept/handle rate
- Request rate
- Response codes

**Nodes Dashboard** (dashboards/nodes.json):
- CPU usage per core
- Memory usage
- Disk I/O
- Network traffic
- System load

**Dashboard Configuration** (dashboards/dashboards.yaml):

```yaml
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /etc/grafana/provisioning/dashboards
```

### Grafana Datasource (datasources/datasources.yaml)

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

## Deployment

### Automatic Deployment (via Terraform)

The stack is automatically deployed when the Prometheus instance is created:

1. Instance launches with cloud-init
2. Cloud-init runs `start.sh`
3. Stack starts automatically

### Manual Deployment

```bash
# SSH to Prometheus instance
ssh demo@[prometheus-instance-ip]

cd ~/stack-prometheus

# Start stack
./start.sh

# Check status
docker compose ps
```

## Scripts

### start.sh

**Purpose**: Initialize and start the monitoring stack

**Actions**:
1. Create htpasswd file with instance ID (for testing)
2. Pull latest Docker images
3. Start all services with docker compose

**Usage**:
```bash
./start.sh
```

### scaletest.sh

**Purpose**: Manually inject test alerts for testing auto-scaling

**Actions**:
1. Creates a test alert with `doaction=true` label
2. Sends to AlertManager
3. Triggers webhook handler

**Usage**:
```bash
# Test container scale up
./scaletest.sh

# Modify script to test different actions
# Edit the alert labels: action=container-down, worker-up, worker-down
```

**Example Alert Injection**:
```bash
curl -X POST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "doaction": "true",
    "action": "container-up",
    "instance_id": "i-xxxxx"
  },
  "annotations": {
    "summary": "Test scaling alert"
  }
}]'
```

## Monitoring and Alerting

### Viewing Metrics

**Prometheus Web UI**:
```
http://[prometheus-instance-ip]:9090
```

**Useful Queries**:

```promql
# Request rate per instance
rate(nginx_http_response_count_total[5m])

# Average response time
histogram_quantile(0.90, rate(nginx_http_response_time_seconds_bucket[5m]))

# CPU usage by instance
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Number of service-a containers
count(up{job="workers"})

# Error rate
rate(nginx_http_response_count_total{status=~"5.."}[5m])
```

### Viewing Alerts

**Active Alerts**:
```
http://[prometheus-instance-ip]:9090/alerts
```

**AlertManager UI**:
```
http://[prometheus-instance-ip]:9093
```

### Grafana Dashboards

**Access Grafana**:
```
http://[prometheus-instance-ip]:3000
Username: admin
Password: 12341234  # SECURITY: Change this password in production!
```

**View Dashboards**:
1. Click "Dashboards" in sidebar
2. Select dashboard:
   - Demo (overall status)
   - Nginx (web server metrics)
   - Nodes (system metrics)

### Telegram Notifications

**Setup**:
1. Create Telegram bot via @BotFather
2. Get bot token
3. Get chat ID (send message to bot, check updates)
4. Update `alertmanager.yml` with credentials
5. Restart AlertManager

**Receive Alerts**:
- Critical alerts sent to Telegram
- Includes alert name, severity, description
- HTML formatted

## Auto-Scaling

### How It Works

1. **Prometheus** evaluates alert rules every 15 seconds
2. **Alert fires** when condition is met (e.g., high CPU)
3. **AlertManager** receives alert and routes based on labels
4. **Webhook** (if `doaction=true`) sent to wh service
5. **wh service** parses alert and executes action:
   - `container-up/down`: Uses AWS SSM to run `scale.sh` on instance
   - `worker-up/down`: Uses Auto Scaling API to adjust desired capacity

### Scaling Actions

**Container Scaling** (via SSM):
```
HighRequestRate → container-up → scale.sh $(expr $current + 1)
LowRequestRate → container-down → scale.sh $(expr $current - 1)
```

**Instance Scaling** (via Auto Scaling API):
```
HighCPU → worker-up → Increase desired capacity
LowCPU → worker-down → Decrease desired capacity
```

### Testing Auto-Scaling

**Test Container Scaling**:
```bash
# Inject high request rate alert
./scaletest.sh

# Check wh logs
docker compose logs -f wh

# Verify on worker instance
ssh demo@[worker-ip]
docker ps | grep service-a
```

**Generate Real Load**:
```bash
# Install hey or similar load testing tool
hey -z 10m -c 100 http://[nlb-dns]/api/

# Watch Grafana dashboard for scaling
# Check Prometheus alerts
# Monitor Telegram for notifications
```

## Troubleshooting

### Check Service Status

```bash
# View all services
docker compose ps

# Check logs
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f alertmanager
docker compose logs -f wh
```

### Prometheus Issues

**Check Configuration**:
```bash
# Validate config
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Validate rules
docker compose exec prometheus promtool check rules /etc/prometheus/rules.yml
```

**Check Targets**:
- Navigate to http://[prometheus-ip]:9090/targets
- Verify all worker instances are discovered
- Check for scrape errors

**Check Service Discovery**:
- Navigate to http://[prometheus-ip]:9090/service-discovery
- Verify EC2 service discovery is working
- Check IAM role has EC2 describe permissions

### AlertManager Issues

**Check Alert Routing**:
```bash
# View AlertManager logs
docker compose logs alertmanager

# Check alert status
curl http://localhost:9093/api/v1/alerts
```

**Test Webhook**:
```bash
# Send test alert
curl -X POST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {"alertname": "test"},
  "annotations": {"summary": "test"}
}]'
```

### Grafana Issues

**Reset Password**:
```bash
docker compose exec grafana grafana-cli admin reset-admin-password newpassword
```

**Check Datasource**:
- Login to Grafana
- Configuration → Data Sources
- Test connection to Prometheus

**Reload Dashboards**:
```bash
# Restart Grafana
docker compose restart grafana
```

### Webhook Handler (wh) Issues

**Check Logs**:
```bash
docker compose logs -f wh
```

**Test Webhook Endpoint**:
```bash
curl -X POST http://localhost:9999/webhook -d '{
  "alerts": [{
    "labels": {
      "action": "container-up",
      "instance_id": "i-xxxxx"
    }
  }]
}'
```

**Verify IAM Permissions**:
- Check instance IAM role has SSM and Auto Scaling permissions
- Test AWS API access from container

## Customization

### Adjust Alert Thresholds

Edit `rules.yml`:

```yaml
# Change CPU threshold from 50% to 70%
- alert: HighCPU
  expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 70

# Change request rate threshold
- alert: HighRequestRate
  expr: rate(nginx_http_response_count_total[5m]) / ... > 100  # from 50
```

### Add Custom Dashboards

1. Create dashboard in Grafana UI
2. Export JSON (Share → Export)
3. Save to `dashboards/custom.json`
4. Restart Grafana or wait for auto-reload

### Add Custom Alerts

Edit `rules.yml`:

```yaml
groups:
  - name: custom
    interval: 15s
    rules:
      - alert: CustomAlert
        expr: your_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Custom alert fired"
```

### Change Data Retention

Edit `docker-compose.yml`:

```yaml
prometheus:
  command:
    - '--storage.tsdb.retention.time=30d'  # from 7d
```

## Performance Tuning

### Prometheus Performance

```yaml
# Increase memory for Prometheus
services:
  prometheus:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Grafana Performance

```yaml
# Add caching
environment:
  - GF_RENDERING_SERVER_URL=http://renderer:8081/render
  - GF_RENDERING_CALLBACK_URL=http://grafana:3000/
```

## Security

- Grafana admin password should be changed from default
- Consider adding authentication to Prometheus/AlertManager
- Telegram bot token should be kept secret
- IAM role permissions are scoped to minimum required
- No sensitive data in metrics or alerts

## Best Practices

1. Monitor Prometheus resource usage
2. Set up alerting on alert rule failures
3. Regularly review and tune alert thresholds
4. Test auto-scaling before production use
5. Back up Grafana dashboards and Prometheus data
6. Use alert silences during maintenance
7. Monitor AlertManager for notification failures
8. Review Telegram alerts regularly

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [PromQL Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

---

Copyright (c) 2025 Serhii Nesterenko
