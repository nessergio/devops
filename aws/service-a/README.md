# service-a

A lightweight HTTP service written in Go that provides configurable responses with simulated latency. Designed for load testing, auto-scaling demonstrations, and performance benchmarking.

## Overview

service-a is a simple HTTP server that:
- Returns a configurable payload (default: "Hello, World!")
- Simulates variable latency (0-10 seconds random delay)
- Supports connection limiting for load testing
- Provides health check endpoint for load balancers
- Runs efficiently in containerized environments

This service is designed to demonstrate auto-scaling behavior under load and is deployed as multiple replicas across worker instances.

## Features

- **Configurable Response**: Set custom payload via environment variable
- **Simulated Latency**: Random delay 0-10 seconds per request (for realistic load testing)
- **Connection Limiting**: Limit concurrent connections to simulate resource constraints
- **Health Checks**: Dedicated endpoint for load balancer health checks
- **Lightweight**: Built on scratch base image (minimal attack surface)
- **Structured Logging**: Uses charmbracelet/log for beautiful logging

## Architecture

```
Request → nginx (reverse proxy)
            ↓
         service-a:8080
            ├─ / (main endpoint with latency)
            └─ /health (health check)
```

Multiple instances of service-a run behind nginx, which load balances requests across all replicas.

## Files

```
service-a/
├── main.go        # Application source code
├── Dockerfile     # Multi-stage Docker build
├── go.mod         # Go module dependencies
└── go.sum         # Dependency checksums
```

## Building

### Prerequisites

- Go 1.21.5 or later
- Docker (for containerization)

### Local Build

```bash
# Build binary
go build -o service-a main.go

# Run locally
./service-a
```

### Docker Build

The Dockerfile uses multi-stage builds for minimal image size:

```bash
# Build image
docker build -t service-a:latest .

# Run container
docker run -p 8080:8080 service-a:latest
```

**Build Stages**:
1. **Build stage**: golang:latest (compile Go binary)
2. **Runtime stage**: scratch (minimal base, ~10MB final image)

### Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin [registry-url]

# Tag image
docker tag service-a:latest [registry-url]/service-a:production

# Push image
docker push [registry-url]/service-a:production
```

## Configuration

### Environment Variables

**A_PAYLOAD** (optional):
- Response payload returned by the main endpoint
- Default: "Hello, World!"
- Example: "This is a custom response"

**PORT** (optional):
- Port to listen on
- Default: 3000
- Note: Container exposes port 8080 (mapped in docker-compose)

**MAX_CONN** (optional):
- Maximum concurrent connections
- Default: 0 (unlimited)
- Example: 100 (limit to 100 concurrent connections)

### Example Configuration

**Docker Compose**:
```yaml
services:
  service-a:
    image: ${REGISTRY}/service-a:${ENVIRONMENT}
    environment:
      - A_PAYLOAD=Custom Response!
      - MAX_CONN=50
    ports:
      - "8080:3000"
```

**Docker Run**:
```bash
docker run -e A_PAYLOAD="Test" -e MAX_CONN=100 -p 8080:3000 service-a:latest
```

## API Endpoints

### GET /

**Purpose**: Main application endpoint

**Behavior**:
1. Receives request
2. Generates random delay (0-10000 milliseconds)
3. Logs delay duration
4. Sleeps for delay duration
5. Returns configured payload

**Response**:
```
HTTP/1.1 200 OK
Content-Type: text/plain

Hello, World!
```

**Example**:
```bash
curl http://localhost:8080/

# Response (after 0-10 second delay):
Hello, World!
```

**Logging**:
```
INFO recieved payload request. Will process for 7234 ms
```

### GET /health

**Purpose**: Health check endpoint for load balancers

**Behavior**:
- Returns immediately (no delay)
- Always returns 200 OK if service is running

**Response**:
```
HTTP/1.1 200 OK
Content-Type: text/plain

Healthcheck OK
```

**Example**:
```bash
curl http://localhost:8080/health

# Response (immediate):
Healthcheck OK
```

**Use Case**: Used by AWS NLB target group for health checks

## Code Structure

### main.go

**Key Functions**:

**getEnv(key, fallback string) string**:
- Retrieves environment variable or returns fallback value
- Used for configuration management

**getHealth(w http.ResponseWriter, r *http.Request)**:
- Health check endpoint handler
- Returns "Healthcheck OK\n"

**getPayload(w http.ResponseWriter, r *http.Request)**:
- Main endpoint handler
- Simulates processing with random delay (0-10 seconds)
- Returns configured payload

**main()**:
- Initializes configuration from environment
- Sets up HTTP router with endpoints
- Configures server timeouts
- Optionally limits concurrent connections
- Starts HTTP server

**Server Configuration**:
```go
srv := http.Server{
    ReadHeaderTimeout: time.Second * 5,   // Header read timeout
    ReadTimeout:       time.Second * 10,  // Full request timeout
    Handler:           router,
}
```

**Connection Limiting**:
```go
if maxConn > 0 {
    listener = netutil.LimitListener(listener, maxConn)
}
```

## Deployment

### In Worker Stack

The service is deployed as part of the worker stack via Docker Compose:

**Location**: `stack-worker/docker-compose.yml`

**Configuration**:
```yaml
services:
  service-a:
    image: ${REGISTRY}/service-a:${ENVIRONMENT}
    ports:
      - "8080:3000"
    networks:
      - app
    restart: unless-stopped
```

**Scaling**:
```bash
# Scale to 5 replicas
cd ~/stack-worker
./scale.sh 5
```

### Direct Docker Deployment

```bash
# Run single instance
docker run -d \
  -p 8080:3000 \
  -e A_PAYLOAD="Hello from Docker!" \
  --name service-a \
  service-a:latest

# Check logs
docker logs -f service-a

# Test endpoint
curl http://localhost:8080/
```

## Testing

### Local Testing

```bash
# Start service
go run main.go

# Test main endpoint
curl http://localhost:3000/

# Test health endpoint
curl http://localhost:3000/health

# Test with custom payload
A_PAYLOAD="Custom!" go run main.go
curl http://localhost:3000/
```

### Load Testing

**Using hey**:
```bash
# Install hey
go install github.com/rakyll/hey@latest

# Generate load (100 concurrent, 60 seconds)
hey -z 60s -c 100 http://localhost:8080/

# Monitor logs to see latency simulation
docker compose logs -f service-a
```

**Using ab (Apache Bench)**:
```bash
# 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://localhost:8080/
```

### Connection Limit Testing

```bash
# Run with connection limit
docker run -e MAX_CONN=5 -p 8080:3000 service-a:latest

# Generate load exceeding limit
hey -z 30s -c 20 http://localhost:8080/

# Observe connection limiting in logs
```

## Performance

### Metrics

**Resource Usage** (single instance):
- Memory: ~5-10MB
- CPU: Minimal (depends on request rate)
- Disk: ~10MB container image
- Network: Depends on payload size and request rate

**Latency**:
- Health check: <1ms
- Main endpoint: 0-10 seconds (simulated)
- Actual processing: <1ms

### Optimization

**For Production** (remove latency simulation):

Edit main.go:
```go
func getPayload(w http.ResponseWriter, r *http.Request) {
    // Remove these lines:
    // delay := rand.Intn(10000)
    // log.Infof("recieved payload request. Will process for %d ms", delay)
    // time.Sleep(time.Duration(delay) * time.Millisecond)

    if _, err := io.WriteString(w, payload); err != nil {
        log.Errorf("can not write response")
    }
}
```

**Increase Timeouts** (for long-running requests):
```go
srv := http.Server{
    ReadHeaderTimeout: time.Second * 10,
    ReadTimeout:       time.Second * 60,  // Increase from 10
    Handler:           router,
}
```

## Troubleshooting

### Service Won't Start

**Check port conflicts**:
```bash
# Check if port is in use
lsof -i :3000

# Use different port
PORT=8081 go run main.go
```

**Check logs**:
```bash
# Docker logs
docker logs service-a

# Application logs (if running locally)
# Logs are written to stdout
```

### Connection Issues

**Connection refused**:
- Verify service is running: `docker ps | grep service-a`
- Check port mapping: `docker port service-a`
- Verify firewall rules

**Connection timeout**:
- Remember: main endpoint has 0-10 second delay
- Check ReadTimeout configuration
- Use `/health` endpoint for quick tests

### High Response Times

**Expected behavior**:
- Main endpoint has intentional random delay (0-10 seconds)
- This is by design for load testing

**If using in production**:
- Remove latency simulation from code
- Rebuild and redeploy

### Memory Issues

**Container OOM killed**:
```yaml
# Add resource limits to docker-compose.yml
services:
  service-a:
    deploy:
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M
```

## Development

### Dependencies

**Go Modules**:
```
github.com/charmbracelet/log  # Structured logging
golang.org/x/net/netutil      # Connection limiting
```

**Install dependencies**:
```bash
go mod download
```

### Code Style

**Logging**:
```go
log.Infof("message with value: %s", value)   // Info level
log.Warnf("warning message")                  // Warning level
log.Errorf("error occurred")                  # Error level
log.Fatal(err)                                # Fatal (exits)
```

**Error Handling**:
```go
if err != nil {
    log.Errorf("operation failed")
    return
}
```

### Adding Features

**Example: Add custom headers**:
```go
func getPayload(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("X-Custom-Header", "value")
    // ... rest of function
}
```

**Example: Add metrics endpoint**:
```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

func main() {
    // ... existing code
    router.Handle("/metrics", promhttp.Handler())
    // ... rest of main
}
```

## Security

- Runs as non-root user in container
- No shell in final image (scratch base)
- Minimal attack surface (only HTTP server)
- Request timeouts prevent slowloris attacks
- Connection limiting prevents resource exhaustion

## Best Practices

1. **Always use environment variables** for configuration
2. **Don't hardcode values** in the code
3. **Use health checks** for proper load balancer integration
4. **Log appropriately** (info for requests, error for failures)
5. **Handle errors gracefully** (don't panic)
6. **Set proper timeouts** to prevent hung connections
7. **Use multi-stage builds** to minimize image size
8. **Tag images properly** (use environment names)

## Production Considerations

### Removing Latency Simulation

For production use, remove the sleep delay:
1. Edit `main.go`
2. Remove lines 32-34 in getPayload function
3. Rebuild and push image

### Adding Authentication

```go
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if token != "expected-token" {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        next(w, r)
    }
}

// In main:
router.HandleFunc("/", authMiddleware(getPayload))
```

### Adding Metrics

Use Prometheus client library:
```go
import "github.com/prometheus/client_golang/prometheus"

var (
    requestsTotal = prometheus.NewCounter(...)
    requestDuration = prometheus.NewHistogram(...)
)
```

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko

## Contributing

This is a demonstration service. Modify as needed for your use case.
