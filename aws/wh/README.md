# wh (Webhook Handler)

An intelligent webhook receiver that integrates Prometheus alerts with AWS infrastructure to enable automated, metric-driven scaling of both containers and EC2 instances.

## Overview

The webhook handler (wh) is a Go-based service that:
- Receives alert notifications from Prometheus AlertManager
- Parses alert metadata and labels
- Executes automated scaling actions via AWS APIs
- Manages both container-level and instance-level scaling
- Provides observability through structured logging

This service is the bridge between your monitoring system and infrastructure automation, enabling true self-healing and auto-scaling capabilities.

## Architecture

```
Prometheus → AlertManager → wh:9999/webhook
                                ↓
                    ┌───────────┴───────────┐
                    ↓                       ↓
              AWS SSM API             Auto Scaling API
                    ↓                       ↓
         Run scale.sh on instance    Adjust ASG capacity
                    ↓                       ↓
           Scale containers          Scale EC2 instances
```

## Features

- **Multi-Level Scaling**: Both container and instance scaling
- **AWS Integration**: Native integration with SSM and Auto Scaling APIs
- **Alert Processing**: Parses Prometheus AlertManager webhook format
- **Action Routing**: Routes alerts to appropriate scaling functions
- **Status Tracking**: Monitors SSM command execution to completion
- **Boundary Enforcement**: Respects ASG min/max size limits
- **Health Checks**: Provides health endpoint for monitoring
- **IAM Role Based**: Uses instance IAM role for AWS authentication

## Files

```
wh/
├── main.go        # Application source code
├── Dockerfile     # Container build definition
├── go.mod         # Go module dependencies
└── go.sum         # Dependency checksums
```

## Scaling Actions

### Container-Level Actions

**container-up**:
- Increases service-a replicas on a specific instance
- Executed via AWS SSM SendCommand
- Command: `su - demo -c 'cd ~/demo/stack-worker && bash scale.sh up'`
- Triggered by: HighRequestRate alert

**container-down**:
- Decreases service-a replicas on a specific instance
- Executed via AWS SSM SendCommand
- Command: `su - demo -c 'cd ~/demo/stack-worker && bash scale.sh down'`
- Triggered by: LowRequestRate alert

### Instance-Level Actions

**worker-up**:
- Increases Auto Scaling Group desired capacity by 1
- Respects ASG maximum size
- Executed via Auto Scaling API
- Triggered by: HighCPU alert

**worker-down**:
- Decreases Auto Scaling Group desired capacity by 1
- Respects ASG minimum size
- Executed via Auto Scaling API
- Triggered by: LowCPU alert

## Alert Format

### AlertManager Webhook Payload

```json
{
  "version": "4",
  "groupKey": "{}:{alertname=\"HighRequestRate\"}",
  "status": "firing",
  "receiver": "webhook",
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighRequestRate",
        "severity": "critical",
        "action": "container-up",
        "instance": "i-xxxxxxxxxxxxx",
        "doaction": "true"
      },
      "annotations": {
        "summary": "High request rate detected",
        "description": "Request rate is 75 req/s per container"
      },
      "startsAt": "2024-05-28T10:00:00Z",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ]
}
```

### Required Labels

**action** (required):
- Values: `container-up`, `container-down`, `worker-up`, `worker-down`
- Determines which scaling function to execute

**instance** (required for container actions):
- EC2 instance ID (e.g., `i-0123456789abcdef0`)
- Used for SSM SendCommand target
- Not required for worker-up/down actions

**doaction** (required):
- Must be `"true"` for action to be processed
- Safety flag to prevent accidental scaling

**severity** (optional):
- Used for logging (e.g., `critical`, `warning`)

## AWS Permissions

### Required IAM Policy

The Prometheus instance IAM role must have:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:DescribeInstanceInformation"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:SetDesiredCapacity"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

### SSM Prerequisites

Worker instances must:
1. Have SSM agent installed and running
2. Have IAM role with SSM managed instance core policy
3. Be registered with SSM (visible in Systems Manager console)
4. Have network connectivity to SSM endpoints

## Building

### Prerequisites

- Go 1.21 or later
- Docker (for containerization)
- AWS credentials (for testing)

### Local Build

```bash
# Build binary
go build -o wh main.go

# Run locally
AWS_REGION=eu-central-1 ./wh
```

### Docker Build

```bash
# Build image
docker build -t wh:latest .

# Run container
docker run -p 9999:3000 \
  -e AWS_REGION=eu-central-1 \
  -e PORT=3000 \
  wh:latest
```

### Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin [registry-url]

# Tag and push
docker tag wh:latest [registry-url]/wh:production
docker push [registry-url]/wh:production
```

## Configuration

### Environment Variables

**AWS_REGION** (required):
- AWS region for API calls
- Example: `eu-central-1`
- Used by AWS SDK

**PORT** (optional):
- Port to listen on
- Default: `3000`
- Container usually exposes as 9999

**AWS_ACCESS_KEY_ID** (optional):
- AWS access key (if not using IAM role)
- Prefer IAM role for production

**AWS_SECRET_ACCESS_KEY** (optional):
- AWS secret key (if not using IAM role)
- Prefer IAM role for production

### Example Configuration

**Docker Compose** (stack-prometheus/docker-compose.yml):
```yaml
services:
  wh:
    image: ${REGISTRY}/wh:${ENVIRONMENT}
    ports:
      - "9999:3000"
    environment:
      - AWS_REGION=${AWS_REGION}
    restart: unless-stopped
```

## API Endpoints

### POST / (Webhook)

**Purpose**: Receive alert notifications from AlertManager

**Request**:
- Method: POST
- Content-Type: application/json
- Body: AlertManager webhook payload

**Response**:
```
HTTP/1.1 200 OK
```

**Example**:
```bash
curl -X POST http://localhost:9999/ -d '{
  "status": "firing",
  "alerts": [{
    "labels": {
      "action": "container-up",
      "instance": "i-xxxxx",
      "doaction": "true",
      "severity": "critical"
    }
  }]
}'
```

**Processing**:
1. Decode JSON payload
2. Check status is "firing"
3. Iterate through alerts
4. Extract action and instance labels
5. Route to appropriate scaling function
6. Execute AWS API calls
7. Return success

### GET /health

**Purpose**: Health check endpoint

**Response**:
```
HTTP/1.1 200 OK
Content-Type: text/plain

Healthcheck OK
```

**Example**:
```bash
curl http://localhost:9999/health
```

## Code Structure

### Data Structures

**msgDef**:
- Top-level AlertManager webhook message
- Contains array of alerts
- Includes metadata (version, receiver, status)

**alertDef**:
- Individual alert definition
- Contains labels (action, instance, severity)
- Contains annotations (summary, description)
- Includes timing (startsAt, endsAt)

**ssmClient**:
- Wrapper for AWS SDK clients
- Contains SSM client for command execution
- Contains Auto Scaling client for capacity changes

### Key Functions

**newSSMClient() *ssmClient**:
- Initializes AWS session
- Creates SSM and Auto Scaling clients
- Returns client wrapper

**getSomeInstance() string**:
- Queries SSM for available instances
- Returns first instance ID
- Used for fallback if instance not specified

**sendCommand(cmd string, instanceId string) string**:
- Sends shell command via SSM
- Waits for command completion (polls every 1 second)
- Returns command status (Success/Failed/Error)

**scaleWorker(delta int64)**:
- Adjusts Auto Scaling Group capacity
- Gets current ASG configuration
- Calculates new capacity within min/max bounds
- Calls SetDesiredCapacity API

**scaleContainerUp(instanceId string)**:
- Scales containers up on specific instance
- Calls sendCommand with `scale.sh up`
- Logs success/failure

**scaleContainerDown(instanceId string)**:
- Scales containers down on specific instance
- Calls sendCommand with `scale.sh down`
- Logs success/failure

**notify(w http.ResponseWriter, r *http.Request)**:
- Main webhook handler
- Decodes AlertManager payload
- Routes alerts to scaling functions
- Handles errors

## Deployment

### In Prometheus Stack

Deployed as part of stack-prometheus:

**Location**: `stack-prometheus/docker-compose.yml`

```yaml
services:
  wh:
    image: ${REGISTRY}/wh:${ENVIRONMENT}
    ports:
      - "9999:3000"
    environment:
      - AWS_REGION=${AWS_REGION}
    networks:
      - monitoring
    restart: unless-stopped
```

**Accessed by**: AlertManager at http://wh:9999/webhook

### Standalone Deployment

```bash
# Run as Docker container
docker run -d \
  -p 9999:3000 \
  -e AWS_REGION=eu-central-1 \
  --name wh \
  wh:latest

# Check logs
docker logs -f wh

# Test webhook
curl -X POST http://localhost:9999/ -d '...'
```

## Testing

### Local Testing

**Start service**:
```bash
export AWS_REGION=eu-central-1
go run main.go
```

**Send test webhook**:
```bash
curl -X POST http://localhost:3000/ \
  -H "Content-Type: application/json" \
  -d '{
    "status": "firing",
    "alerts": [{
      "labels": {
        "action": "container-up",
        "instance": "i-xxxxx",
        "doaction": "true",
        "severity": "critical"
      },
      "annotations": {
        "summary": "Test alert"
      }
    }]
  }'
```

**Check logs**:
```
INFO Got critical Alert for instance i-xxxxx: container-up
INFO CONTAINER UP
DEBUG sending command su - demo -c 'cd ~/demo/stack-worker && bash scale.sh up' to i-xxxxx
DEBUG output: Scaling up...
DEBUG result: Success
INFO Scaled successfully!
```

### Integration Testing

**Via Prometheus scaletest.sh**:
```bash
# SSH to Prometheus instance
ssh demo@[prometheus-ip]

# Run test script
cd ~/stack-prometheus
./scaletest.sh

# Check wh logs
docker compose logs -f wh
```

**Via AlertManager UI**:
1. Navigate to http://[prometheus-ip]:9093
2. Click "New Silence" to test alert creation
3. Add labels: `action=container-up`, `instance=i-xxxxx`, `doaction=true`
4. Check wh logs for processing

### AWS Permissions Testing

**Test SSM access**:
```bash
# List instances
aws ssm describe-instance-information

# Send test command
aws ssm send-command \
  --instance-ids i-xxxxx \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["echo test"]
```

**Test Auto Scaling access**:
```bash
# Describe ASG
aws autoscaling describe-auto-scaling-groups

# Test capacity change (careful!)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name [asg-name] \
  --desired-capacity 2
```

## Monitoring

### Logs

**Log Levels**:
- DEBUG: Command details, output, status
- INFO: Scaling actions, success messages
- WARN: Failures, unknown actions
- ERROR: AWS API errors, decoding errors

**Example Logs**:
```
INFO Starting server on port 3000..
INFO Got critical Alert for instance i-0abc: container-up
INFO CONTAINER UP
DEBUG sending command su - demo -c 'cd ~/demo/stack-worker && bash scale.sh up' to i-0abc
DEBUG output: Scaling service-a to 3 replicas
DEBUG result: Success
INFO Scaled successfully!

INFO Got critical Alert for instance : worker-up
INFO WORKER-UP
INFO MIN: 1 MAX: 6 CAP: 2
INFO Desired capacity set to 3
```

### Health Checks

```bash
# Check service health
curl http://localhost:9999/health

# Check via Docker
docker exec wh curl http://localhost:3000/health
```

### Metrics

Consider adding Prometheus metrics:
- Total webhooks received
- Webhooks by action type
- Scaling operations success/failure
- AWS API call latency

## Troubleshooting

### Webhook Not Receiving Alerts

**Check AlertManager configuration**:
```bash
# View AlertManager config
docker compose exec alertmanager cat /etc/alertmanager/alertmanager.yml

# Check webhook URL is correct
# Should be: http://wh:9999/webhook or http://wh:9999/
```

**Check network connectivity**:
```bash
# From AlertManager container
docker compose exec alertmanager wget -O- http://wh:9999/health
```

**Check wh logs**:
```bash
docker compose logs -f wh
```

### SSM Commands Failing

**Check SSM agent on worker**:
```bash
ssh demo@[worker-ip]
sudo systemctl status amazon-ssm-agent
```

**Check instance is registered**:
```bash
aws ssm describe-instance-information
```

**Check IAM role permissions**:
```bash
# On worker instance
aws sts get-caller-identity
aws ssm describe-instance-information  # Should work
```

**Check command manually**:
```bash
aws ssm send-command \
  --instance-ids i-xxxxx \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["su - demo -c 'cd ~/demo/stack-worker && bash scale.sh up'"]
```

### Auto Scaling Not Working

**Check ASG exists**:
```bash
aws autoscaling describe-auto-scaling-groups
```

**Check IAM permissions**:
```bash
# From Prometheus instance
aws autoscaling describe-auto-scaling-groups  # Should work
aws autoscaling set-desired-capacity --help   # Should show help
```

**Check ASG limits**:
- Verify desired capacity not at min/max
- Check wh logs for MIN/MAX/CAP values

**Manually test scaling**:
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name [asg-name] \
  --desired-capacity 3
```

### JSON Parsing Errors

**Check AlertManager payload format**:
```bash
# Capture webhook payload
# Add logging in notify function to print raw body
```

**Test with known-good payload**:
```bash
curl -X POST http://localhost:9999/ -d '{
  "status": "firing",
  "alerts": [{"labels": {"action": "worker-up", "doaction": "true"}}]
}'
```

### Unknown Action

**Check alert labels**:
- Verify `action` label is set
- Verify value is one of: container-up, container-down, worker-up, worker-down
- Check for typos in Prometheus rules

## Security

- Uses IAM role for AWS authentication (no hardcoded credentials)
- Requires `doaction=true` label to prevent accidental scaling
- Respects ASG min/max boundaries
- SSM commands run as demo user (not root)
- No shell command injection (SSM API handles escaping)
- Health endpoint has no sensitive information

## Best Practices

1. **Always test alerts** before production (use scaletest.sh)
2. **Monitor wh logs** during scaling events
3. **Set appropriate ASG min/max** to prevent over-scaling
4. **Use doaction flag** to control which alerts trigger actions
5. **Verify IAM permissions** are minimal but sufficient
6. **Test SSM connectivity** on all worker instances
7. **Alert on wh failures** (add health check monitoring)
8. **Review scaling thresholds** regularly

## Development

### Adding New Actions

1. Add new case in switch statement:
```go
case "custom-action":
    log.Info("CUSTOM ACTION")
    sc.executeCustomAction(alert.Labels["param"])
```

2. Implement action function:
```go
func (sc *ssmClient) executeCustomAction(param string) {
    // Your implementation
}
```

3. Create Prometheus alert rule with `action=custom-action`

### Adding Metrics

```go
import "github.com/prometheus/client_golang/prometheus"

var (
    webhooksTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "wh_webhooks_total",
            Help: "Total webhooks received",
        },
        []string{"action", "status"},
    )
)

func init() {
    prometheus.MustRegister(webhooksTotal)
}

// In notify function:
webhooksTotal.WithLabelValues(action, "success").Inc()
```

### Error Handling Improvements

```go
// Retry logic for SSM commands
func (sc *ssmClient) sendCommandWithRetry(cmd, instanceId string, retries int) string {
    for i := 0; i < retries; i++ {
        result := sc.sendCommand(cmd, instanceId)
        if result == "Success" {
            return result
        }
        time.Sleep(time.Duration(i+1) * time.Second)
    }
    return "Failed"
}
```

## Performance

### Resource Usage

- Memory: ~20-30MB
- CPU: Minimal (event-driven)
- Network: Low (only during alerts)

### Optimization

**Async command execution**:
```go
// Don't wait for SSM command completion
func (sc *ssmClient) sendCommandAsync(cmd, instanceId string) {
    go func() {
        result := sc.sendCommand(cmd, instanceId)
        log.Infof("Command result: %s", result)
    }()
}
```

**Batch operations**:
```go
// Scale multiple instances at once
func (sc *ssmClient) scaleContainerUpBatch(instanceIds []string) {
    var wg sync.WaitGroup
    for _, id := range instanceIds {
        wg.Add(1)
        go func(instanceId string) {
            defer wg.Done()
            sc.scaleContainerUp(instanceId)
        }(id)
    }
    wg.Wait()
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko

## Contributing

This is a demonstration service. Extend as needed for your infrastructure automation requirements.
