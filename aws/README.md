# AWS Auto-Scaling Infrastructure with Monitoring

## Kubernetes-Free Cloud-Native Architecture

A comprehensive demonstration of how to build scalable, self-healing web application infrastructure on AWS **without Kubernetes**. This project proves that flexible, production-ready auto-scaling can be achieved using native AWS services, Docker Compose, and intelligent automation.

## Overview

This project showcases that you **don't need Kubernetes** to achieve modern cloud-native capabilities. Instead, it demonstrates:

- **Docker Compose orchestration** instead of Kubernetes pods and deployments
- **AWS Auto Scaling Groups** instead of K8s HorizontalPodAutoscaler
- **Native AWS services** (EC2, SSM, CodeDeploy) instead of K8s control plane
- **Multi-level auto-scaling** (both EC2 instances and application containers)
- **Metric-driven automation** with Prometheus + custom webhook handlers
- **Full observability** with Prometheus, Grafana, and AlertManager
- **Infrastructure as Code** with Terraform (simpler than Helm charts)
- **Self-healing infrastructure** without the complexity of Kubernetes

### Why Not Kubernetes?

This architecture demonstrates that for many use cases, Kubernetes is **overkill**. Benefits of this approach:

- ✅ **Simpler to understand and maintain** - No K8s abstractions (pods, services, ingresses, etc.)
- ✅ **Lower operational overhead** - No control plane to manage, upgrade, or troubleshoot
- ✅ **Reduced costs** - No master nodes, simpler networking, t2.micro instances
- ✅ **Faster deployment** - Docker Compose vs. complex Kubernetes manifests
- ✅ **Direct AWS integration** - Native AWS APIs instead of cloud controller managers
- ✅ **Easier debugging** - Standard Linux tools, no kubectl complexity
- ✅ **Flexible scaling** - Custom logic via webhooks, not limited to K8s metrics

This project is **perfect for**:
- Teams wanting container orchestration without K8s complexity
- Startups and small-to-medium workloads
- Learning modern DevOps without the Kubernetes learning curve
- Demonstrating that "cloud-native" ≠ "must use Kubernetes"

## Architecture

### High-Level Architecture

```
Internet (IPv4/IPv6)
    ↓
Cloudflare DNS
    ↓
Network Load Balancer (Elastic IPs)
    ↓
Auto Scaling Group (1-6 workers)
    ↓
Worker Instances (Ubuntu 24.04)
    ├─ service-a (Go HTTP service)
    ├─ nginx (reverse proxy)
    └─ exporters (metrics)
         ↓
Prometheus Instance
    ├─ Prometheus (metrics collection)
    ├─ Grafana (visualization)
    ├─ AlertManager (alerting)
    └─ wh (webhook handler for auto-scaling)
```

### Components (The Kubernetes Alternative)

| Kubernetes Equivalent | This Project Uses | Why It's Better |
|-----------------------|-------------------|-----------------|
| Kubernetes Service | AWS Network Load Balancer | Native AWS integration, simpler networking |
| HorizontalPodAutoscaler | Custom Prometheus + Webhook | More flexible, any metric-based scaling |
| Deployment/ReplicaSet | Docker Compose + scale.sh | Simpler, direct container control |
| Kubernetes Nodes | AWS Auto Scaling Group | Native AWS auto-scaling, no kubelet overhead |
| kubectl | AWS SSM + Docker Compose | Standard tools, no new CLI to learn |
| Helm Charts | Terraform | Industry-standard IaC, better AWS support |
| Ingress Controller | Nginx reverse proxy | Simple, proven, lightweight |
| K8s Metrics Server | Prometheus + Exporters | More powerful, flexible metrics |

**Architecture Components**:
- **Network Load Balancer**: Layer 4 load balancer distributing traffic (replaces K8s Service)
- **Auto Scaling Group**: 1-6 worker instances with native AWS auto-scaling (replaces K8s nodes)
- **Worker Instances**: Run Docker Compose stacks (replaces K8s pods)
- **Monitoring Instance**: Prometheus, Grafana, AlertManager (better than K8s metrics-server)
- **VPC**: Custom VPC (172.16.0.0/16) with IPv6 support across multiple AZs

## Project Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Provider and Route53 configuration
│   ├── vpc.tf             # VPC, subnets, security groups
│   ├── worker.tf          # Worker instances and ASG
│   ├── prometheus.tf      # Monitoring instance
│   ├── load_balancer.tf   # Network Load Balancer
│   ├── codedeploy.tf      # CodeDeploy configuration
│   ├── cloudflare.tf      # DNS configuration
│   └── bootstrap/         # S3 backend setup
├── stack-worker/          # Application stack for worker nodes
│   ├── docker-compose.yml # Service definitions
│   ├── nginx.conf         # Nginx configuration
│   ├── start.sh           # Deployment script
│   ├── stop.sh            # Cleanup script
│   └── scale.sh           # Container scaling script
├── stack-prometheus/      # Monitoring stack
│   ├── docker-compose.yml # Monitoring services
│   ├── prometheus.yml     # Prometheus configuration
│   ├── alertmanager.yml   # Alert routing
│   ├── rules.yml          # Alert rules
│   └── dashboards/        # Grafana dashboards
├── service-a/             # Go HTTP service
│   ├── main.go            # Application code
│   └── Dockerfile         # Multi-stage build
└── wh/                    # Webhook handler for auto-scaling
    ├── main.go            # Webhook receiver and AWS integration
    └── Dockerfile         # Container build
```

## Technology Stack

### The Kubernetes-Free Stack

This project uses **standard, proven technologies** instead of K8s complexity:

### Infrastructure (vs. Kubernetes Control Plane)
- **Terraform** ~5.0 - Infrastructure as Code *(simpler than Helm/Kustomize)*
- **AWS** - Cloud platform (eu-central-1) *(native services, no EKS overhead)*
- **Cloudflare** - DNS management *(vs. ExternalDNS operator)*

### Orchestration (vs. Kubernetes)
- **Docker** - Containerization *(same as K8s, but without pod abstractions)*
- **Docker Compose** v2 - Multi-container orchestration *(replaces K8s Deployments/StatefulSets)*
- **AWS Auto Scaling Groups** - Instance scaling *(replaces K8s Cluster Autoscaler)*
- **Custom Webhook Handler** - Intelligent scaling *(more flexible than K8s HPA)*

### Application
- **Go** 1.21.5 - Application language
- **Nginx** 1.25 - Reverse proxy and load balancer *(replaces K8s Ingress Controller)*
- **Amazon ECR** - Container registry *(same as K8s, but simpler auth)*

### Monitoring & Observability (Better than K8s Metrics Server)
- **Prometheus** - Metrics collection and alerting *(more powerful than K8s metrics)*
- **Grafana** - Visualization and dashboards
- **AlertManager** - Alert routing and notification
- **Node Exporter** - System metrics
- **Nginx Exporter** - Web server metrics
- **Exporter Merger** - Metric aggregation

### AWS Services (Instead of K8s Components)
- **EC2** - Compute *(vs. K8s worker nodes with kubelet overhead)*
- **VPC** - Networking *(simpler than K8s CNI plugins)*
- **Auto Scaling** - Instance scaling *(native AWS, no K8s controllers)*
- **CodeDeploy** - Deployment *(replaces K8s rolling updates)*
- **SSM** - Remote command execution *(simpler than kubectl exec)*
- **IAM** - Access management *(native AWS vs. K8s RBAC complexity)*
- **Route53** - Private DNS *(vs. K8s CoreDNS)*
- **S3** - Terraform state *(vs. etcd)*
- **Network Load Balancer** - Load balancing *(vs. K8s Service)*

### What's NOT Needed (Thanks to No Kubernetes!)
- ❌ etcd cluster management
- ❌ kube-apiserver, kube-scheduler, kube-controller-manager
- ❌ kubelet, kube-proxy on every node
- ❌ CNI plugins (Calico, Flannel, etc.)
- ❌ CSI drivers for storage
- ❌ Service mesh (Istio, Linkerd)
- ❌ kubectl, kubeconfig management
- ❌ K8s RBAC complexity
- ❌ CRDs, operators, admission controllers
- ❌ K8s version upgrades and compatibility issues

## Features

### Multi-Level Auto-Scaling (Without Kubernetes!)

This project demonstrates **two-tier auto-scaling** similar to Kubernetes HPA + Cluster Autoscaler, but simpler:

**Container-Level Scaling** (1-10 containers per instance):
- **Replaces**: Kubernetes HorizontalPodAutoscaler
- **How it works**: Docker Compose scale command via AWS SSM
- **Trigger**: Request rate per container (Prometheus metrics)
- High request rate (>50 req/container) → scale up
- Low request rate (≤1 req/container) → scale down
- **Advantage**: No K8s scheduler overhead, direct container control

**Instance-Level Scaling** (1-6 EC2 instances):
- **Replaces**: Kubernetes Cluster Autoscaler
- **How it works**: Native AWS Auto Scaling Groups
- **Trigger**: CPU utilization (Prometheus metrics)
- High CPU (>50%) → add instances
- Low CPU (≤1%) → remove instances
- **Advantage**: Native AWS integration, no K8s node lifecycle complexity

**Why This Is Better Than K8s**:
- ✅ Any metric can trigger scaling (not just CPU/memory)
- ✅ Custom webhook logic (more flexible than K8s admission controllers)
- ✅ Faster scaling decisions (no K8s scheduler delays)
- ✅ Simpler debugging (standard bash scripts, not K8s controllers)

### Monitoring and Alerting

**Metrics Collected**:
- System metrics (CPU, memory, disk, network)
- Application metrics (request rate, response times, status codes)
- Nginx metrics (connections, requests)
- Container metrics

**Alert Rules**:
- **InstanceDown**: Instance unreachable >1 minute
- **InstanceFault**: 5+ 4xx errors in 5 minutes
- **HighRequestRate**: >50 requests/container
- **LowRequestRate**: ≤1 request/container
- **HighCPU**: >50% CPU utilization
- **LowCPU**: ≤1% CPU utilization
- **HighRequestLatency**: 90th percentile >1 second

**Alert Routing**:
- Critical alerts → Telegram notifications
- Scaling alerts → Webhook handler (automated actions)

### Deployment

**Infrastructure Deployment**:
- Fully automated via Terraform
- Multi-AZ deployment for high availability
- Dual-stack networking (IPv4 and IPv6)

**Application Deployment**:
- Automated via AWS CodeDeploy
- In-place deployment strategy (OneAtATime)
- Automatic health checks via target groups
- Zero-downtime deployments

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 5.0
- AWS CLI configured
- Cloudflare account (for DNS)
- Docker (for local development)

### Infrastructure Setup

1. **Bootstrap Terraform Backend**:
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd ../
   terraform init
   terraform apply
   ```

3. **Configure Variables**:
   Edit `terraform/variables.tf` or create `terraform.tfvars`:
   ```hcl
   aws_region = "eu-central-1"
   environment = "production"
   # Add Cloudflare and other credentials
   ```

### Accessing Services

**Via Load Balancer** (after deployment):
- Application: `http://[load-balancer-dns]/`
- Grafana: `http://[load-balancer-dns]/grafana/` (admin/12341234 - **Change password in production!**)
- Prometheus: `http://[load-balancer-dns]/prometheus/`

**Direct Access** (within VPC):
- Prometheus Instance: Check Terraform outputs for private IP
- Worker Instances: Via SSH using demo user

### Monitoring

**Grafana Dashboards**:
1. **Demo Dashboard**: Overall application status, response times, request rates
2. **Nginx Dashboard**: Nginx-specific metrics and performance
3. **Nodes Dashboard**: System-level metrics for all instances

**Prometheus**:
- EC2 service discovery automatically detects worker instances
- Scrapes metrics every 15 seconds
- 7-day data retention

### Manual Scaling

**Scale Containers on Worker**:
```bash
# SSH to worker instance
ssh demo@[worker-ip]

# Scale service-a to 5 containers
cd ~/stack-worker
./scale.sh 5
```

**Trigger Test Alert**:
```bash
# SSH to Prometheus instance
ssh demo@[prometheus-ip]

# Inject test alert
cd ~/stack-prometheus
./scaletest.sh
```

## Configuration

### Environment Variables

**Worker Nodes**:
- `REGISTRY`: ECR registry URL
- `ENVIRONMENT`: Deployment environment (used for image tags)
- `AWS_REGION`: AWS region
- `AWS_DEFAULT_REGION`: AWS default region

**service-a**:
- `PAYLOAD`: Response payload (default: "Hello, World!")
- `MAX_CONN`: Maximum concurrent connections

### Alert Configuration

Edit `stack-prometheus/alertmanager.yml` to configure:
- Telegram bot token and chat ID
- Webhook URLs
- Alert grouping and throttling

### Scaling Thresholds

Edit `stack-prometheus/rules.yml` to adjust:
- Request rate thresholds
- CPU utilization thresholds
- Alert evaluation intervals

## Architecture Details

### Network Architecture
- **VPC**: 172.16.0.0/16 with IPv6
- **Subnets**: One per availability zone
- **Security Groups**:
  - Public: HTTP (80), SSH (22), Metrics (8080)
  - Prometheus: Prometheus (9090), Grafana (3000)
- **DNS**: Private Route53 zone (demo.local) for internal resolution

### Application Flow
1. User request → NLB → Worker nginx
2. Nginx routes `/api/*` → service-a container
3. Nginx serves static files from `/public`
4. Nginx proxies `/prometheus` and `/grafana` to monitoring instance
5. All metrics exposed on port 8080 (merged endpoint)

### Monitoring Flow
1. Exporters collect metrics → Exporter Merger (port 8080)
2. Prometheus discovers workers via EC2 tags (`worker=true`)
3. Prometheus scrapes merged metrics every 15s
4. Prometheus evaluates alert rules
5. Alerts sent to AlertManager
6. AlertManager routes to Telegram and/or webhook handler
7. Webhook handler executes scaling actions via AWS API

## Development

### Building service-a
```bash
cd service-a
docker build -t service-a:latest .
```

### Building webhook handler
```bash
cd wh
docker build -t wh:latest .
```

### Testing Locally
```bash
cd stack-worker
docker-compose up -d
curl http://localhost/api/hello
```

## Troubleshooting

### Check Instance Health
```bash
# View ASG status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names [asg-name]

# Check CodeDeploy deployments
aws deploy list-deployments --application-name [app-name]
```

### Check Container Status
```bash
# SSH to worker
ssh demo@[worker-ip]

# View running containers
docker ps

# Check logs
docker-compose logs -f service-a
```

### Check Metrics
- Verify exporters are running: `curl http://[worker-ip]:8080/metrics`
- Check Prometheus targets: Navigate to `/prometheus/targets`
- Review Grafana dashboards for anomalies

## Security Considerations

- SSH access restricted via security groups
- IAM roles with least-privilege permissions
- Private subnets for internal communication
- Secrets managed via AWS SSM Parameter Store (for production)
- Security group rules limit access to necessary ports only

## Cost Optimization

This Kubernetes-free approach is significantly **cheaper** than EKS/K8s:

### Cost Comparison: This Project vs. EKS

| Component | This Project | EKS (Kubernetes) | Monthly Savings |
|-----------|-------------|------------------|-----------------|
| Control Plane | $0 (no masters) | $73 (EKS cluster) | $73 |
| Worker Nodes | 2x t2.micro ($8) | 2x t3.medium required ($60) | $52 |
| Load Balancer | NLB ($16) | ALB + Ingress ($22) | $6 |
| Monitoring | Self-hosted ($0) | Managed Prometheus ($30+) | $30+ |
| **Total** | **~$24/month** | **~$185/month** | **~$161/month** |

### Additional Cost Benefits:
- ✅ Uses t2.micro instances (AWS Free Tier eligible, K8s needs larger instances)
- ✅ Auto-scaling reduces costs during low traffic (same as K8s, but simpler)
- ✅ 7-day metric retention to limit storage costs
- ✅ Network Load Balancer instead of Application Load Balancer
- ✅ No NAT Gateway required for private subnets (simpler networking)
- ✅ No EKS cluster hourly charges ($0.10/hour = $73/month)
- ✅ No managed node group overhead
- ✅ Smaller instance types (K8s requires minimum t3.medium for worker nodes)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko

## When to Use This vs. Kubernetes

### ✅ Use This Approach When:
- You have < 50 services/microservices
- Your team is small (< 10 engineers)
- You want simpler operations and debugging
- Cost is a concern
- You're building on AWS (native integration)
- You don't need multi-cloud portability
- You want faster time-to-production
- Your engineers know Linux/Docker but not K8s

### ❌ Consider Kubernetes When:
- You have 100+ microservices
- You need multi-cloud/hybrid cloud
- You have a dedicated platform team
- You need advanced features (service mesh, GitOps, etc.)
- Vendor lock-in is a concern
- You're already invested in K8s ecosystem

### The Truth About Kubernetes

Kubernetes is powerful but **not always necessary**. This project proves:
- 🎯 **You can achieve the same auto-scaling capabilities** without K8s complexity
- 🎯 **Modern DevOps ≠ Kubernetes** - there are simpler alternatives
- 🎯 **Docker Compose + AWS = Production Ready** for many workloads
- 🎯 **Lower complexity = Higher reliability** - fewer moving parts

## Contributing

This is a demonstration project showcasing **flexible architecture without Kubernetes**.

**Educational Value**:
- Learn container orchestration without K8s complexity
- Understand cloud-native patterns (auto-scaling, observability, IaC)
- See how native cloud services can replace K8s components
- Practice with Terraform, Prometheus, Docker Compose

Feel free to fork and adapt for your needs. This architecture is production-ready for many use cases!

## Support

For issues or questions, please open a GitHub issue.

## Credits

This project demonstrates that **simplicity beats complexity**. Inspired by teams tired of Kubernetes overhead who just want containers to scale automatically.
