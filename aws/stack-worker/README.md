# Worker Stack

## Docker Compose Instead of Kubernetes Pods

This directory contains the Docker Compose stack that runs on each worker instance. This demonstrates that **Docker Compose can replace Kubernetes** for container orchestration with much less complexity.

## Overview: Docker Compose vs. Kubernetes

### What This Replaces

| Kubernetes Concept | This Project Uses | Simplification |
|--------------------|-------------------|----------------|
| Pod (multi-container) | Docker Compose services | Same concept, simpler syntax |
| Deployment | docker-compose.yml | No YAML complexity, direct container control |
| Service (internal) | Docker network | Built-in DNS, no K8s abstractions |
| Scaling | docker compose scale / scale.sh | Simple command vs. K8s replicas |
| Health checks | Container restart policy | Built-in, no liveness/readiness probes |
| Resource limits | Docker Compose deploy limits | Simpler than K8s resource quotas |

### The Stack

The worker stack is deployed on each EC2 instance in the Auto Scaling Group and consists of:

- **service-a**: The main Go HTTP application (scalable 1-10 containers) - *replaces K8s Deployment*
- **nginx**: Reverse proxy and static file server - *replaces K8s Ingress Controller*
- **nginx-exporter**: Prometheus exporter for nginx metrics
- **nginxlogs-exporter**: Prometheus exporter parsing nginx access logs
- **node-exporter**: System metrics (CPU, memory, disk, network)
- **exporter-merger**: Consolidates metrics into single endpoint - *simpler than K8s sidecar pattern*

**Key Advantage**: All of this in **one docker-compose.yml file** instead of multiple K8s manifests (Deployment, Service, Ingress, ConfigMap, etc.)

## Architecture

```
Internet → NLB → nginx:80 → service-a (1-10 containers)
                      │
                      ├─ /api/* → service-a
                      ├─ /public/* → static files
                      ├─ /prometheus → prometheus instance
                      └─ /grafana → grafana on prometheus instance

Metrics Flow:
service-a → [implicit]
nginx → nginx-exporter:9113
nginx logs → nginxlogs-exporter:9114
system → node-exporter:9100
                      ↓
            exporter-merger:8080
                      ↓
            Prometheus (scrapes)
```

## Files

```
stack-worker/
├── docker-compose.yml    # Service definitions
├── nginx.conf           # Nginx reverse proxy configuration
├── nginxlogsexp.yml     # Nginx logs exporter configuration
├── appspec.yml          # AWS CodeDeploy specification
├── start.sh             # Deployment startup script
├── stop.sh              # Deployment stop script
└── scale.sh             # Container scaling script
```

## Services

### service-a

**Purpose**: Main application service

**Configuration**:
- Image: Pulled from Amazon ECR
- Tag: `${ENVIRONMENT}` (e.g., production, staging)
- Ports: Internal only (accessed via nginx)
- Scaling: 1-10 replicas (dynamic)
- Network: app network

**Environment Variables**:
- `PAYLOAD`: Response content (default: "Hello, World!")
- `MAX_CONN`: Max concurrent connections (optional)

**Endpoints**:
- `/`: Main endpoint (returns payload)
- `/health`: Health check endpoint

### nginx

**Purpose**: Reverse proxy, load balancer, static file server

**Configuration**:
- Image: nginx:1.25
- Port: 80 (exposed to load balancer)
- Volume: ./nginx.conf → /etc/nginx/nginx.conf
- Volume: /var/log/nginx (shared with nginxlogs-exporter)

**Routing**:
- `/api/*` → service-a (load balanced across all replicas)
- `/public/*` → static files from /var/www/html
- `/prometheus/` → Prometheus instance (reverse proxy)
- `/grafana/` → Grafana instance (reverse proxy)
- `/stub_status` → nginx metrics (for nginx-exporter)

**Features**:
- Custom log format for metrics parsing
- Upstream load balancing with least_conn algorithm
- Proxy buffering and timeouts configured
- IPv6 support

### nginx-exporter

**Purpose**: Export nginx connection and request metrics

**Configuration**:
- Image: nginx/nginx-prometheus-exporter:latest
- Port: 9113 (internal)
- Scrape: http://nginx/stub_status

**Metrics Exported**:
- Active connections
- Accepted/handled connections
- Total requests
- Reading/writing/waiting states

### nginxlogs-exporter

**Purpose**: Parse nginx access logs for response time metrics

**Configuration**:
- Image: quay.io/martinhelmich/prometheus-nginxlog-exporter:v1
- Port: 9114 (internal)
- Volume: Shared /var/log/nginx
- Config: ./nginxlogsexp.yml

**Metrics Exported**:
- HTTP response times (histogram)
- Request counts by status code
- Request counts by method
- Bytes sent

**Log Format** (from nginx.conf):
```
nginx_prometheus $remote_addr - $remote_user [$time_local] "$request"
                 $status $body_bytes_sent "$http_referer"
                 "$http_user_agent" rt=$request_time
```

### node-exporter

**Purpose**: System and hardware metrics

**Configuration**:
- Image: prom/node-exporter:latest
- Port: 9100 (internal)
- Volumes: Host filesystem mounts (read-only)
  - /proc → /host/proc
  - /sys → /host/sys
  - / → /rootfs

**Metrics Exported**:
- CPU usage
- Memory usage
- Disk I/O and space
- Network traffic
- System load

### exporter-merger

**Purpose**: Consolidate all metrics into single endpoint

**Configuration**:
- Image: rebuy/exporter-merger:latest
- Port: 8080 (exposed to Prometheus)
- Aggregates:
  - nginx-exporter:9113
  - nginxlogs-exporter:9114
  - node-exporter:9100

**Endpoint**:
- http://[worker-ip]:8080/metrics (scraped by Prometheus)

## Deployment

### Automatic Deployment (CodeDeploy)

The stack is automatically deployed via AWS CodeDeploy:

1. **ApplicationStop**: `stop.sh` stops all containers
2. **DownloadBundle**: CodeDeploy downloads application bundle
3. **ApplicationStart**: `start.sh` starts the stack

**CodeDeploy Lifecycle** (appspec.yml):
```yaml
version: 0.0
os: linux
files:
  - source: /
    destination: /home/demo/stack-worker
hooks:
  ApplicationStop:
    - location: stop.sh
  ApplicationStart:
    - location: start.sh
```

### Manual Deployment

```bash
# SSH to worker instance
ssh demo@[worker-ip]

cd ~/stack-worker

# Start stack
./start.sh

# Stop stack
./stop.sh
```

## Scripts

### start.sh

**Purpose**: Initialize and start the Docker Compose stack

**Actions**:
1. Authenticate to Amazon ECR
2. Pull latest images
3. Start all services with docker compose
4. Scale service-a to 2 replicas initially

**Usage**:
```bash
./start.sh
```

**Environment Variables Required**:
- `REGISTRY`: ECR registry URL
- `ENVIRONMENT`: Environment tag for images
- `AWS_REGION`: AWS region

### stop.sh

**Purpose**: Stop and remove all containers

**Actions**:
1. Stop all services
2. Remove containers
3. Clean up networks and volumes

**Usage**:
```bash
./stop.sh
```

### scale.sh

**Purpose**: Dynamically scale service-a containers

**Actions**:
1. Validate input (1-10 replicas)
2. Scale service-a to specified number
3. Update running containers

**Usage**:
```bash
# Scale to 5 replicas
./scale.sh 5

# Scale to 1 replica
./scale.sh 1

# Scale to 10 replicas (max)
./scale.sh 10
```

**Called By**:
- Webhook handler (wh) when HighRequestRate or LowRequestRate alerts fire
- Executed via AWS SSM SendCommand

## Configuration

### Nginx Configuration (nginx.conf)

Key settings:

```nginx
# Upstream for service-a (load balancing)
upstream service-a {
    least_conn;  # Load balancing algorithm
    server service-a:8080;
}

# Server block
server {
    listen 80;

    # API routing
    location /api/ {
        proxy_pass http://service-a/;
    }

    # Static files
    location /public/ {
        alias /var/www/html/;
    }

    # Prometheus reverse proxy
    location /prometheus/ {
        proxy_pass http://prometheus.demo.local:9090/;
    }

    # Grafana reverse proxy
    location /grafana/ {
        proxy_pass http://prometheus.demo.local:3000/;
    }
}
```

### Nginxlogs Exporter Config (nginxlogsexp.yml)

```yaml
namespaces:
  - name: nginx
    format: "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" rt=$request_time"
    source:
      files:
        - /var/log/nginx/access.log
```

## Scaling

### Container-Level Scaling (Docker Compose vs. Kubernetes HPA)

This demonstrates that Docker Compose can achieve the same auto-scaling as Kubernetes HorizontalPodAutoscaler (HPA), but **simpler**:

| Feature | Kubernetes HPA | This Project (Docker Compose) |
|---------|----------------|-------------------------------|
| Scale trigger | CPU/Memory only (by default) | **Any Prometheus metric** |
| Configuration | K8s HPA YAML + metrics-server | Simple Prometheus alert rules |
| Execution | K8s controller (complex) | Bash script via AWS SSM (simple) |
| Debugging | kubectl describe hpa | Standard logs, SSH to instance |
| Custom metrics | Requires K8s custom metrics API | Native Prometheus queries |

**Manual Scaling**:
```bash
./scale.sh <number>  # 1-10 replicas
# vs. Kubernetes: kubectl scale deployment service-a --replicas=5
```

**Automatic Scaling** (via Prometheus alerts):

**Scale Up** (HighRequestRate alert):
- Trigger: >50 requests/container in 5 minutes *(any metric, not just CPU)*
- Action: Add containers (up to 10 max)
- Command: `scale.sh $((current + 1))`
- **Advantage**: Scales on business metrics, not just resource usage

**Scale Down** (LowRequestRate alert):
- Trigger: ≤1 request/container in 5 minutes
- Action: Remove containers (down to 1 min)
- Command: `scale.sh $((current - 1))`

**Scaling Logic** (simpler than K8s):
1. Prometheus evaluates alert rules *(same as K8s metrics-server)*
2. Alert sent to AlertManager *(no K8s API server required)*
3. AlertManager sends webhook to wh service *(custom logic, more flexible)*
4. wh executes SSM SendCommand on specific instance *(vs. K8s scheduler)*
5. scale.sh adjusts container count via Docker Compose *(direct, no K8s abstractions)*

**Why This Is Better**:
- ✅ Scale on ANY metric (requests, errors, custom business metrics)
- ✅ Simpler logic (bash script vs. K8s controllers)
- ✅ Faster execution (no K8s scheduler latency)
- ✅ Easy to debug (standard Linux tools)

### Viewing Current Scale

```bash
# Check running containers
docker ps | grep service-a

# Check via docker compose
docker compose ps service-a

# Get replica count
docker compose ps service-a --format json | jq length
```

## Networking

### Docker Networks

**app** network:
- Type: Bridge
- Purpose: Internal communication between services
- Services: service-a, nginx, exporters

### Port Mapping

| Service | Internal Port | Exposed Port | Access |
|---------|--------------|--------------|--------|
| nginx | 80 | 80 | Public (via NLB) |
| service-a | 8080 | - | Internal only |
| exporter-merger | 8080 | 8080 | Prometheus |
| nginx-exporter | 9113 | - | Internal (via merger) |
| nginxlogs-exporter | 9114 | - | Internal (via merger) |
| node-exporter | 9100 | - | Internal (via merger) |

## Metrics

### Available Metrics

Access merged metrics:
```bash
curl http://[worker-ip]:8080/metrics
```

**service-a metrics** (implicit via nginx):
- Request count (from nginx logs)
- Response times (from nginx logs)
- Error rates (from nginx logs)

**nginx metrics**:
- `nginx_connections_active`: Active connections
- `nginx_connections_accepted`: Total accepted connections
- `nginx_http_requests_total`: Total HTTP requests

**nginxlogs metrics**:
- `nginx_http_response_time_seconds`: Response time histogram
- `nginx_http_response_count_total`: Requests by status code

**node metrics**:
- `node_cpu_seconds_total`: CPU usage
- `node_memory_MemAvailable_bytes`: Available memory
- `node_disk_io_time_seconds_total`: Disk I/O
- `node_network_receive_bytes_total`: Network traffic

## Troubleshooting

### Check Service Status

```bash
# View all services
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f service-a
docker compose logs -f nginx
```

### Check Nginx Configuration

```bash
# Test nginx config syntax
docker compose exec nginx nginx -t

# Reload nginx (after config changes)
docker compose exec nginx nginx -s reload
```

### Check Metrics Endpoints

```bash
# Merged metrics
curl http://localhost:8080/metrics

# Individual exporters
curl http://localhost:9100/metrics  # node-exporter
curl http://localhost:9113/metrics  # nginx-exporter
curl http://localhost:9114/metrics  # nginxlogs-exporter
```

### Debug service-a

```bash
# Check if service-a is responding
docker compose exec nginx curl http://service-a:8080/

# Scale to specific count
./scale.sh 3

# Check number of replicas
docker compose ps service-a
```

### Common Issues

**Issue**: service-a containers not starting
```bash
# Check logs
docker compose logs service-a

# Check ECR authentication
aws ecr get-login-password --region $AWS_REGION

# Verify image exists
aws ecr describe-images --repository-name service-a
```

**Issue**: Nginx not proxying correctly
```bash
# Check nginx config
docker compose exec nginx cat /etc/nginx/nginx.conf

# Check nginx error log
docker compose logs nginx | grep error
```

**Issue**: Metrics not appearing
```bash
# Check exporter-merger
curl http://localhost:8080/metrics

# Check individual exporters
curl http://localhost:9100/metrics
curl http://localhost:9113/metrics
curl http://localhost:9114/metrics
```

## Development

### Local Testing

```bash
# Start stack locally
export REGISTRY="your-registry"
export ENVIRONMENT="dev"
docker compose up -d

# Test application
curl http://localhost/api/hello

# Test static files
echo "test" > /tmp/test.txt
docker compose exec nginx mkdir -p /var/www/html
docker compose cp /tmp/test.txt nginx:/var/www/html/
curl http://localhost/public/test.txt

# Check metrics
curl http://localhost:8080/metrics
```

### Modifying nginx Configuration

1. Edit `nginx.conf`
2. Test configuration:
   ```bash
   docker compose exec nginx nginx -t
   ```
3. Reload nginx:
   ```bash
   docker compose exec nginx nginx -s reload
   ```
4. Deploy via CodeDeploy or restart stack

### Adding New Services

1. Add service to `docker-compose.yml`
2. If service exposes metrics, add to exporter-merger URLs
3. Update `start.sh` if needed
4. Test locally
5. Deploy via CodeDeploy

## Performance Tuning

### Nginx Tuning

Edit `nginx.conf`:

```nginx
worker_processes auto;  # Use all CPU cores
worker_connections 1024;  # Connections per worker

# Caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
```

### service-a Tuning

Adjust environment variables:

```yaml
environment:
  MAX_CONN: 100  # Increase concurrent connections
```

### Container Resource Limits

Add to `docker-compose.yml`:

```yaml
services:
  service-a:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Security

- All internal services are not exposed to the internet
- Only nginx port 80 is accessible via load balancer
- Metrics endpoint (8080) is restricted by security group to Prometheus
- No sensitive data in logs
- Docker socket not mounted (security best practice)

## Best Practices

1. Always use `./start.sh` for deployment (handles ECR auth)
2. Monitor logs during scaling operations
3. Test configuration changes locally before deploying
4. Use CodeDeploy for production deployments
5. Keep image tags updated in ECR
6. Monitor merged metrics endpoint health
7. Review nginx access logs regularly

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Prometheus Exporters](https://prometheus.io/docs/instrumenting/exporters/)
- [AWS CodeDeploy AppSpec Reference](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html)

---

Copyright (c) 2025 Serhii Nesterenko
