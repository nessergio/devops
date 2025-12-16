# Root Chart

Root application chart implementing the App of Apps pattern for ArgoCD GitOps deployments.

## Overview

This chart creates ArgoCD Application resources that manage child applications in the cluster. It follows the ArgoCD App of Apps pattern where a single root application creates and manages multiple child applications.

## Components

### ArgoCD Applications

- **test**: Main test application deployment
  - Source: Charts repository, `test/` path
  - Destination: default namespace
  - Sync Policy: Automated with prune and self-heal

### ImageUpdater Resources

The root chart includes ImageUpdater CRD resources to enable automatic image updates based on digest changes.

#### test-image-updater

Monitors the test application and automatically updates when new image digests are pushed to ACR.

**Configuration:**
- **Target Application**: `test`
- **Image**: `{{.Values.acr}}/test:{{.Values.tag}}`
- **Update Strategy**: `digest` - Detects new image digests even with the same tag
- **Tag Filter**: Only monitors the specified tag (prevents unintended updates)
- **Write-back Method**: `argocd` - Directly updates Application spec

**Behavior:**

When a new Docker image is pushed to ACR with the same tag but a different digest (e.g., a new build of `latest`), the ImageUpdater controller will:
1. Detect the digest change
2. Update the Application's image specification
3. Trigger ArgoCD to sync the new image to the cluster

This enables automatic deployments when the CI/CD pipeline builds and pushes new images.

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env` | Environment name | `Development` |
| `acr` | Azure Container Registry hostname | `myorg.azurecr.io` |
| `hostname` | Application ingress hostname | `myapp.example.com` |
| `tag` | Docker image tag to monitor | `latest` |
| `branch` | Git branch for charts repository | `master` |
| `tls_secret_name` | TLS secret name for ingress | `myapp-tls` |
| `charts_repo` | Charts repository URL | Azure DevOps Charts repo |

## Usage

This chart is typically deployed by Terraform as part of the infrastructure layer:

```yaml
# Deployed via argocd-apps Helm chart in Terraform
applications:
  root:
    namespace: argocd
    project: default
    source:
      repoURL: <charts-repo-url>
      targetRevision: master
      path: root
      helm:
        values: |
          acr: "myacr.azurecr.io"
          hostname: "myapp.example.com"
          tag: "latest"
```

## Deployment Flow

1. Infrastructure Terraform deploys the root Application via argocd-apps chart
2. ArgoCD syncs the root chart from the Charts repository
3. Root chart creates child Application resources (test)
4. Root chart creates ImageUpdater resources
5. ArgoCD deploys child applications
6. ImageUpdater controller monitors ACR for image changes
7. When new images are pushed, automatic updates trigger ArgoCD sync

## Monitoring

Check Application status:
```bash
kubectl get applications -n argocd
kubectl describe application test -n argocd
```

Check ImageUpdater status:
```bash
kubectl get imageupdaters -n argocd
kubectl describe imageupdater test-image-updater -n argocd
```

View ImageUpdater logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater
```

## Customization

To add new applications:

1. Create a new Application template in `templates/`
2. Optionally create an ImageUpdater resource for automatic updates
3. Update values.yaml with application-specific configuration
4. Commit and push to Charts repository
5. ArgoCD will automatically sync the changes

## Dependencies

- ArgoCD installed in the cluster
- ArgoCD Image Updater installed in the cluster
- Charts repository configured in ArgoCD
- Azure Container Registry accessible from the cluster

---

For more information, see the [Architecture Documentation](../../docs/ARCHITECTURE.md).

---

© 2025 Serhii Nesterenko
