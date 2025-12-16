# Hello test Helm Chart

A Helm chart for deploying the Hello test web application to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- NGINX Ingress Controller (if using ingress)
- cert-manager (if using TLS with Let's Encrypt)

## Installing the Chart

### Basic Installation

```bash
helm install test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0 \
  --set ingress.hosts[0].host=myapp.example.com \
  --set ingress.tls[0].hosts[0]=myapp.example.com
```

### Installation with Custom Values File

Create a `custom-values.yaml`:

```yaml
image:
  repository: myacr.azurecr.io/test
  tag: v1.0.0

ingress:
  enabled: true
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: test-tls
      hosts:
        - myapp.example.com

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 250m
    memory: 128Mi
```

Install with custom values:

```bash
helm install test ./app/charts/test \
  -f custom-values.yaml
```

## Upgrading the Chart

```bash
helm upgrade test ./app/charts/test \
  --set image.tag=v1.1.0
```

## Uninstalling the Chart

```bash
helm uninstall test
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

### Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag (overrides Chart.appVersion) | `""` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Deployment Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `nameOverride` | Override chart name | `""` |
| `fullnameOverride` | Override full name | `""` |

### Service Account Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `false` |
| `serviceAccount.automount` | Automount service account token | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |

### Security Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext.runAsNonRoot` | Run as non-root user | `true` |
| `podSecurityContext.runAsUser` | User ID | `101` |
| `podSecurityContext.fsGroup` | File system group | `101` |
| `securityContext.allowPrivilegeEscalation` | Allow privilege escalation | `false` |
| `securityContext.readOnlyRootFilesystem` | Read-only root filesystem | `true` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `80` |
| `service.protocol` | Service protocol | `TCP` |
| `service.annotations` | Service annotations | `{}` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.annotations` | Ingress annotations | See values.yaml |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | See values.yaml |

### Resource Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `128Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `64Mi` |

### Health Check Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `livenessProbe.httpGet.path` | Liveness probe path | `/` |
| `livenessProbe.initialDelaySeconds` | Initial delay | `10` |
| `livenessProbe.periodSeconds` | Period | `10` |
| `readinessProbe.httpGet.path` | Readiness probe path | `/` |
| `readinessProbe.initialDelaySeconds` | Initial delay | `5` |
| `readinessProbe.periodSeconds` | Period | `5` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | `nil` |

### Other Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podAnnotations` | Pod annotations | `{}` |
| `podLabels` | Pod labels | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity rules | `{}` |
| `volumes` | Additional volumes | `[]` |
| `volumeMounts` | Additional volume mounts | `[]` |

## Examples

### Enable Horizontal Pod Autoscaling

```bash
helm install test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10 \
  --set autoscaling.targetCPUUtilizationPercentage=70
```

### Deploy with Service Account

```bash
helm install test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0 \
  --set serviceAccount.create=true \
  --set serviceAccount.name=hello-test-sa
```

### Deploy without Ingress

```bash
helm install test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0 \
  --set ingress.enabled=false
```

## Testing the Chart

### Template Validation

```bash
# Validate templates
helm template test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0

# Lint the chart
helm lint ./app/charts/test
```

### Dry Run Installation

```bash
helm install test ./app/charts/test \
  --set image.repository=myacr.azurecr.io/test \
  --set image.tag=v1.0.0 \
  --dry-run --debug
```

## Best Practices Implemented

This Helm chart follows Kubernetes and Helm best practices:

1. **Security**
   - Security contexts defined in values (TODO: apply in deployment template)
   - Values include non-root execution, read-only filesystem settings

2. **Reliability**
   - Liveness and readiness probes configured
   - Resource limits and requests defined
   - Rolling update strategy
   - Optional HPA for autoscaling

3. **Maintainability**
   - All values parameterized
   - Helper templates for DRY code
   - Comprehensive documentation
   - Clear naming conventions

4. **Observability**
   - Post-install NOTES with helpful commands
   - Labels following Kubernetes recommendations
   - Easy log access

5. **Flexibility**
   - Optional ingress
   - Configurable service types
   - Custom annotations support
   - Volume mounts support

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=test
kubectl describe pod <pod-name>
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=test
```

### Check Ingress

```bash
kubectl get ingress
kubectl describe ingress test
```

### Debug Values

```bash
helm get values test
```

## TODO: add securityContext and podSecurityContext

---

© 2025 Serhii Nesterenko
