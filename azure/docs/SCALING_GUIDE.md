# AKS Node Scaling Guide

Complete guide for scaling AKS cluster nodes up or down using the Infrastructure repository and pipeline workflow.

## Overview

The AKS cluster uses autoscaling with configurable bounds:
- `system_node_count` - Initial number of nodes (default: 2)
- `system_node_min_count` - Minimum nodes for autoscaling (default: 1)
- `system_node_max_count` - Maximum nodes for autoscaling (default: 5)

These parameters control how your cluster scales to meet demand while managing costs.

## Scaling Process

### Step 1: Clone or Navigate to Infrastructure Repository

```bash
# If not already cloned
cd ~/workspace
git clone https://<your-pat>@dev.azure.com/<org>/<project>/_git/Infrastructure
cd Infrastructure

# If already cloned, ensure you're up to date
cd ~/workspace/Infrastructure
git pull origin master
```

### Step 2: Modify Node Count Configuration

Edit the `terraform.tfvars` file:

```bash
# Open configuration file
nano terraform.tfvars
```

Modify the node count variables based on your scaling needs:

**Example: Scale up to handle more load**
```hcl
system_node_count     = 3    # Increase initial count
system_node_min_count = 2    # Increase minimum
system_node_max_count = 8    # Increase maximum
```

**Example: Scale down to reduce costs**
```hcl
system_node_count     = 1    # Decrease initial count
system_node_min_count = 1    # Keep minimum at 1
system_node_max_count = 3    # Decrease maximum
```

**Example: Adjust autoscaling bounds only**
```hcl
system_node_count     = 2    # Keep initial count
system_node_min_count = 1    # Allow scaling down to 1
system_node_max_count = 10   # Allow scaling up to 10 during high load
```

### Step 3: Commit and Push Changes

```bash
# Check what changed
git diff terraform.tfvars

# Stage changes
git add terraform.tfvars

# Commit with descriptive message
git commit -m "Scale AKS node pool: min=2, max=8

Increasing node capacity to handle expected traffic increase."

# Push to trigger pipeline
git push origin master
```

### Step 4: Monitor Pipeline Execution

The "Infrastructure Deploy" pipeline will automatically trigger (if configured) or run it manually:

**Option A: Pipeline auto-triggers** (if branch triggers configured)
- Just wait for pipeline to start automatically

**Option B: Manual trigger**
1. Navigate to Azure DevOps → Pipelines
2. Select "Infrastructure Deploy"
3. Click "Run pipeline"
4. Select branch: master
5. Click "Run"

### Step 5: Review and Approve Plan

1. Wait for Validate and Plan stages to complete
2. Review the Terraform plan output
3. Verify the changes show node count modifications:
   ```
   ~ resource "azurerm_kubernetes_cluster" "aks" {
       ~ default_node_pool {
           ~ node_count     = 2 -> 3
           ~ min_count      = 1 -> 2
           ~ max_count      = 5 -> 8
         }
     }
   ```
4. Click "Approve" on the Apply stage
5. Wait for completion (~5-10 minutes for scaling)

### Step 6: Verify Scaling

```bash
# Check current node count
kubectl get nodes

# View node pool details
az aks nodepool show \
  --resource-group rg-aks-infrastructure \
  --cluster-name aks-cluster \
  --name system
```

## Alternative: Manual Scaling via Azure CLI

For immediate scaling without modifying Terraform state, you can use Azure CLI directly.

**Warning:** Manual changes are temporary and will be overwritten on next Terraform apply. For permanent scaling, always update `terraform.tfvars`.

### Manual Scaling Command

```bash
# Scale node pool to specific count
az aks nodepool scale \
    --resource-group rg-aks-infrastructure \
    --cluster-name aks-cluster \
    --name system \
    --node-count 5 # optional --no-wait - skip waiting 

# Monitor scaling progress
kubectl get nodes -w
```

**Best Practice:** Use manual scaling only for emergencies or testing, then follow up with Terraform changes.

## Alternative: Stop and Start AKS Cluster

For maximum cost savings when the cluster is not needed (e.g., development environments during nights/weekends), you can completely stop and start the AKS cluster.

**Warning:** Stopping the cluster makes all applications unavailable. Only use this for non-production environments or during planned maintenance windows.

### Stop AKS Cluster

```bash
# Stop the cluster completely
az aks stop \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster

# Verify cluster is stopped
az aks show \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster \
    --query powerState
```

**Example: Stop cluster for weekend**
```bash
# Friday evening - stop cluster to save costs
az aks stop \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster

# Expected output:
# {
#   "code": "Stopped",
#   "message": null
# }
```

### Start AKS Cluster

```bash
# Start the cluster
az aks start \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster

# Verify cluster is running
az aks show \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster \
    --query powerState

# Wait for nodes to be ready
kubectl get nodes
```

**Example: Start cluster for workday**
```bash
# Monday morning - start cluster for development work
az aks start \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster

# Wait for startup (typically 2-5 minutes)
kubectl get nodes -w

# Verify applications are running
kubectl get pods --all-namespaces
```

### Cost Savings with Stop/Start

**Stopped Cluster Costs:**
- You only pay for storage (disks) and static IPs
- No charges for VMs, compute, or networking
- Typical savings: 70-90% of cluster costs

**When to Use Stop/Start:**
- Development/testing environments during off-hours
- Planned maintenance windows
- Extended periods of non-use (weekends, holidays)

**When NOT to Use Stop/Start:**
- Production environments requiring high availability
- Clusters with strict SLA requirements
- When immediate availability is critical

### Automation Example: Scheduled Stop/Start

You can automate cluster stop/start using Azure Automation or scripts:

```bash
#!/bin/bash
# stop-cluster.sh - Schedule this for Friday 6 PM

az aks stop \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster \
    --no-wait

echo "AKS cluster stop initiated at $(date)"
```

```bash
#!/bin/bash
# start-cluster.sh - Schedule this for Monday 7 AM

az aks start \
    --resource-group rg-aks-infrastructure \
    --name aks-cluster \
    --no-wait

echo "AKS cluster start initiated at $(date)"

# Optional: Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
sleep 180  # Wait 3 minutes

kubectl wait --for=condition=Ready nodes --all --timeout=300s
echo "Cluster is ready at $(date)"
```

**Best Practice:** Always verify cluster state before performing critical operations, and document stop/start schedules for team visibility.

## Scaling Considerations

### When to Scale Up

- **Increased load:** Application experiencing high traffic
- **Resource constraints:** Pods pending due to insufficient resources
- **High availability:** Need more nodes for redundancy
- **New workloads:** Deploying additional applications

### When to Scale Down

- **Reduced load:** Traffic has decreased
- **Cost optimization:** Running more nodes than needed
- **Over-provisioned:** Cluster has excessive unused capacity

### Best Practices

1. **Gradual scaling:** Make incremental changes rather than large jumps
2. **Monitor first:** Check current utilization before scaling
   ```bash
   kubectl top nodes
   kubectl top pods
   ```
3. **Autoscaling bounds:** Set appropriate min/max to allow cluster flexibility
4. **Business hours:** Scale operations during low-traffic periods when possible
5. **Pod disruption:** Scaling down may evict pods; ensure apps handle restarts
6. **Cost awareness:** Each node incurs costs; right-size for actual needs

## Monitoring After Scaling

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Verify application is healthy
kubectl get deployments
kubectl get pods -l app=hello-test

# Check resource utilization
kubectl top nodes
kubectl top pods

# View node details
kubectl describe nodes
```

## Rollback Scaling Changes

If scaling causes issues:

```bash
# In Infrastructure repository
# Revert terraform.tfvars to previous values
git log terraform.tfvars                    # Find previous commit
git diff <previous-commit> terraform.tfvars # Review changes
git checkout <previous-commit> terraform.tfvars

# Commit rollback
git add terraform.tfvars
git commit -m "Rollback node scaling to previous configuration"
git push origin master

# Re-run pipeline and approve
```

## Common Scaling Scenarios

### Scenario 1: Prepare for High Traffic Event

```hcl
# Before event
system_node_count     = 5
system_node_min_count = 5
system_node_max_count = 10

# After event (cost optimization)
system_node_count     = 2
system_node_min_count = 1
system_node_max_count = 5
```

### Scenario 2: Development Environment (Cost-Optimized)

```hcl
system_node_count     = 1
system_node_min_count = 1
system_node_max_count = 2
system_node_vm_size   = "Standard_B2s"  # Also reduce VM size
```

### Scenario 3: Production Environment (High Availability)

```hcl
system_node_count     = 3
system_node_min_count = 3
system_node_max_count = 10
system_node_vm_size   = "Standard_D4s_v3"  # Use larger VMs
```

## Troubleshooting Scaling Issues

### Issue: Nodes Not Scaling

**Symptoms:** Node count doesn't change after pipeline completion

**Solution:**
1. Verify Terraform apply completed successfully
2. Check AKS cluster status in Azure portal
3. Review pipeline logs for errors
4. Verify autoscaler is enabled:
   ```bash
   az aks show --resource-group <rg> --name <aks> --query 'agentPoolProfiles[0].enableAutoScaling'
   ```

### Issue: Pods Pending After Scale Down

**Symptoms:** Pods stuck in Pending state after reducing node count

**Solution:**
1. Check if pods have specific node selectors or taints
2. Ensure sufficient resources on remaining nodes
3. Review pod events:
   ```bash
   kubectl describe pod <pod-name>
   ```
4. May need to scale back up temporarily

### Issue: Pipeline Fails During Scaling

**Symptoms:** Infrastructure Deploy pipeline fails during Apply stage

**Solution:**
1. Review error message in pipeline logs
2. Check if node count values are valid (min < max)
3. Verify Azure subscription has sufficient quota
4. Ensure no conflicting operations on cluster

### Issue: High Costs After Scaling Up

**Symptoms:** Unexpected Azure costs after increasing nodes

**Solution:**
1. Review current node count and VM sizes
2. Check if autoscaler scaled beyond expected bounds
3. Consider scaling down during off-hours
4. Review Azure Cost Management for detailed breakdown

## Understanding Autoscaling

### How Cluster Autoscaler Works

The AKS cluster autoscaler automatically adjusts node count based on:
- **Pod resource requests** (not limits or actual usage)
- **Unschedulable pods** (pending due to insufficient resources)
- **Node utilization** (scales down underutilized nodes)

### Autoscaling Behavior

**Scale Up Triggers:**
- Pods cannot be scheduled due to insufficient resources
- Occurs within minutes of detecting pending pods

**Scale Down Triggers:**
- Node CPU/memory utilization below threshold for 10+ minutes
- All pods can be rescheduled on other nodes
- No pods with local storage (unless using PVCs)

### Autoscaling Limitations

The autoscaler will NOT scale down a node if:
- Pods have `PodDisruptionBudget` preventing eviction
- Pods with local storage (emptyDir)
- Pods with node affinity/selectors preventing movement
- System pods not managed by DaemonSet

## Cost Optimization Tips

1. **Right-size node pools:** Don't over-provision initial count
2. **Set appropriate bounds:** Allow autoscaling within reasonable range
3. **Use smaller VMs:** Standard_B2s for dev, Standard_D2s_v3 for prod
4. **Schedule scaling:** Scale down during nights/weekends if applicable
5. **Monitor utilization:** Use `kubectl top nodes` regularly
6. **Delete unused resources:** Remove idle workloads

## Advanced: Multiple Node Pools

For production environments, consider multiple node pools:

```hcl
# System node pool (created in this guide)
system_node_count     = 2
system_node_min_count = 2
system_node_max_count = 5
system_node_vm_size   = "Standard_D2s_v3"

# User node pool (requires additional Terraform config)
# - Use for application workloads
# - Different VM sizes for different workload types
# - Separate scaling policies
```

**Note:** Adding additional node pools requires modifying the Terraform infrastructure code, not just tfvars.

## Related Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Initial infrastructure deployment
- [PIPELINE_GUIDE.md](PIPELINE_GUIDE.md) - Pipeline operations and troubleshooting
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Common kubectl and Azure CLI commands
- [ARCHITECTURE.md](ARCHITECTURE.md) - Understanding the AKS architecture

---

© 2025 Serhii Nesterenko
