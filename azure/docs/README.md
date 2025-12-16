# Documentation

Complete documentation for the Azure Infrastructure Automation project.

## Documentation Structure

### Getting Started

#### [SETUP_GUIDE.md](SETUP_GUIDE.md)
Complete step-by-step setup guide from prerequisites to deployment.

**Contents:**
- Prerequisites checklist
- Azure and Azure DevOps authentication
- Bootstrap layer deployment
- Infrastructure layer deployment
- Application deployment
- Verification steps
- Common issues and solutions

**Best for:** First-time users, initial project setup

---

### Understanding the System

#### [ARCHITECTURE.md](ARCHITECTURE.md)
Comprehensive architecture documentation and design decisions.

**Contents:**
- System overview
- Layer-by-layer breakdown (Bootstrap, Infrastructure, Application)
- Component descriptions
- Data flow diagrams
- Security architecture
- Scalability and high availability
- Cost optimization
- Disaster recovery

**Best for:** Understanding system design, architectural decisions, troubleshooting complex issues

---

### Daily Operations

#### [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
Fast reference for common commands and operations.

**Contents:**
- Quick start commands
- Terraform commands
- Azure CLI commands
- Kubernetes (kubectl) commands
- Docker commands
- Azure DevOps CLI commands
- Git commands
- Useful one-liners
- Troubleshooting commands

**Best for:** Daily operations, quick lookups, command syntax

#### [SCALING_GUIDE.md](SCALING_GUIDE.md)
Guide for scaling AKS cluster nodes using git workflow and pipelines.

**Contents:**
- Scaling process overview
- Step-by-step scaling instructions
- Git commit and push workflow
- Pipeline execution and approval
- Verification and monitoring
- Common scaling scenarios
- Troubleshooting scaling issues
- Cost optimization tips

**Best for:** Scaling cluster capacity, handling traffic changes, cost optimization

---

### Pipeline Operations

#### [PIPELINE_GUIDE.md](PIPELINE_GUIDE.md)
Complete guide for Azure DevOps pipelines.

**Contents:**
- Pipeline overview
- Infrastructure Deploy pipeline
- Infrastructure Destroy pipeline
- App Deploy pipeline
- Running pipelines
- Troubleshooting pipeline issues
- Pipeline customization
- Security considerations

**Best for:** Running deployments, debugging pipeline failures, customizing CI/CD

---

## Quick Navigation

### By Task

**Setting up for the first time?**
→ Start with [SETUP_GUIDE.md](SETUP_GUIDE.md)

**Need to run a deployment?**
→ See [PIPELINE_GUIDE.md](PIPELINE_GUIDE.md)

**Looking for a specific command?**
→ Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

**Need to scale your cluster?**
→ See [SCALING_GUIDE.md](SCALING_GUIDE.md)

**Want to understand how it works?**
→ Read [ARCHITECTURE.md](ARCHITECTURE.md)

**Troubleshooting an issue?**
→ Check troubleshooting sections in relevant guide

### By Role

**DevOps/Platform Engineer:**
- [PIPELINE_GUIDE.md](PIPELINE_GUIDE.md) - CI/CD operations
- [SCALING_GUIDE.md](SCALING_GUIDE.md) - Cluster scaling
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Daily commands
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design

**Developer:**
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - kubectl and Docker commands
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Local setup
- [PIPELINE_GUIDE.md](PIPELINE_GUIDE.md) - Application deployment

**Solutions Architect:**
- [ARCHITECTURE.md](ARCHITECTURE.md) - Complete architecture
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Implementation details

## Additional Resources

### In Repository

**Root README.md**
- Project overview
- Feature highlights
- Quick start
- Configuration examples

**Layer-Specific READMEs:**
- [bootstrap/README.md](../bootstrap/README.md) - Bootstrap layer
- [infra/README.md](../infra/README.md) - Infrastructure layer
- [app/README.md](../app/README.md) - Application layer

**Architecture Diagrams:**
- [architecture-diagram.drawio](../architecture-diagram.drawio) - High-level flow
- [azure-resources-diagram.drawio](../azure-resources-diagram.drawio) - Detailed resources

### External Links

**Terraform:**
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure DevOps Provider Docs](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs)

**Azure:**
- [ACR Documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure DevOps Docs](https://learn.microsoft.com/en-us/azure/devops/)

**Kubernetes:**
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager](https://cert-manager.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## Documentation Conventions

### Command Examples

Commands are shown with their expected output location:
```bash
# Run from bootstrap directory
cd bootstrap
terraform apply
```

### Placeholders

Text in angle brackets should be replaced:
```bash
az aks get-credentials --resource-group <rg-name> --name <aks-name>
```

### Variable References

Terraform output references:
```bash
$(terraform output -raw variable_name)
```

## Contributing to Documentation

When updating documentation:

1. **Keep it accurate** - Verify commands work
2. **Be concise** - Remove unnecessary details
3. **Use examples** - Show, don't just tell
4. **Update all references** - Keep cross-references current
5. **Test procedures** - Ensure steps work end-to-end

## Documentation Versions

Current documentation version: **1.0.0**

Last updated: December 2024

Corresponds to:
- Terraform Azure Provider: Latest
- Azure DevOps Provider: Latest
- Kubernetes: 1.27+
- Terraform: 1.14+

## Getting Help

If documentation doesn't answer your question:

1. Check layer-specific READMEs in each directory
2. Review troubleshooting sections in relevant guides
3. Search for error messages in documentation
4. Review Azure DevOps pipeline logs
5. Check Azure portal for resource status

## Feedback

Found an issue with documentation?
- Create an issue in the project repository
- Include document name and section
- Suggest specific improvements

---

© 2025 Serhii Nesterenko
