# DevOps Infrastructure Repository

A comprehensive collection of DevOps infrastructure automation tools and configurations for cloud platforms, container orchestration, virtualization, and secrets management.

## Overview

This repository contains production-ready infrastructure automation projects covering major cloud providers, container platforms, and DevOps tooling. Each subproject is fully documented and designed to be used independently or as part of a larger infrastructure strategy.

## Projects

### [AWS - Auto-Scaling Infrastructure](./aws/)

**Kubernetes-Free Cloud-Native Architecture**

A comprehensive demonstration of scalable, self-healing web application infrastructure on AWS without Kubernetes complexity. Features Docker Compose orchestration, AWS Auto Scaling Groups, multi-level auto-scaling, and full observability with Prometheus and Grafana.

**Key Features:**
- Multi-tier auto-scaling (container and instance level)
- Native AWS services (EC2, Auto Scaling, CodeDeploy)
- Prometheus + Grafana monitoring
- Terraform-based infrastructure as code
- Cost-optimized (~$24/month vs ~$185/month for EKS)

**Technologies:** Terraform, Docker Compose, AWS (EC2, Auto Scaling, CodeDeploy), Prometheus, Grafana, Nginx

**Use Case:** Small to medium workloads requiring auto-scaling without Kubernetes overhead

[View AWS Documentation →](./aws/README.md)

---

### [Azure - Infrastructure as Code with CI/CD](./azure/)

**Enterprise-Grade Terraform Automation for Azure**

Complete Azure infrastructure automation with integrated Azure DevOps CI/CD pipelines, self-hosted build agents, and GitOps workflow using ArgoCD. Features three-layer architecture (bootstrap, infrastructure, application) with automated pipeline deployment.

**Key Features:**
- Bootstrap layer creates foundational infrastructure
- Azure Kubernetes Service (AKS) with ArgoCD GitOps
- Self-hosted build agent VM with Docker
- Three automated Azure DevOps pipelines
- Integrated Cert-Manager for TLS certificates
- Azure Container Registry (ACR) integration

**Technologies:** Terraform, Azure (AKS, ACR, DevOps), Kubernetes, ArgoCD, Helm, Docker

**Use Case:** Enterprise Azure deployments with automated CI/CD and GitOps

[View Azure Documentation →](./azure/README.md)

---

### [Packer - Linux Image Builder](./packer/)

**Automated VM Template Creation for Multiple Distributions**

HashiCorp Packer configurations for building Linux virtual machine images across multiple distributions, supporting both VMware environments and VMware Cloud Director deployment.

**Supported Distributions:**
- **Ubuntu Server** - Cloud-init automated installation
- **Oracle Linux** - Kickstart-based deployment
- **Rocky Linux** - Kickstart-based deployment
- **Arch Linux** - Custom script installation

**Key Features:**
- Automated OS installation with cloud-init/Kickstart
- SSH key-based authentication
- Templating engine for secure credential management
- OVA export for VMware compatibility
- Optional Terraform deployment to VMware Cloud Director

**Technologies:** Packer, VMware, Terraform, Cloud-init, Kickstart

**Use Case:** Automated VM template creation for consistent infrastructure provisioning

[View Packer Documentation →](./packer/README.md)

---

### [Vault - HashiCorp Vault Docker Setup](./vault/)

**Containerized Secrets Management**

Production-ready HashiCorp Vault deployment using Docker with automatic unsealing, Raft storage backend for high availability, and multi-environment support (dev/staging/prod).

**Key Features:**
- Automated unsealing on startup
- Raft storage backend for HA
- Cluster support with automatic leader election
- Web UI and API access
- Environment-based secret organization
- Integration examples (envconsul, Python, Docker Compose)

**Technologies:** Docker, HashiCorp Vault, noVNC

**Use Case:** Secure secrets management for applications and infrastructure

[View Vault Documentation →](./vault/README.md)

---

### [Legacy KVM - Supermicro IPMI Access](./legacy-kvm/)

**Browser-Based Access to Legacy KVM Systems**

Docker-based web interface for accessing legacy Supermicro IPMI KVM consoles through modern browsers using noVNC, supporting old Java applet-based systems.

**Key Features:**
- Legacy Java applet support (Java 7)
- Browser-based VNC access via noVNC
- Ubuntu 14.04 + Chromium with Java plugin
- ISO mounting for virtual media
- No local Java plugin installation required

**Technologies:** Docker, noVNC, Java 7, Chromium, Xvfb

**Use Case:** Accessing legacy server IPMI/KVM interfaces that require Java applets

[View Legacy KVM Documentation →](./legacy-kvm/README.md)

---

## Quick Start

Each project is self-contained with its own documentation. Navigate to the respective directory and follow the README instructions.

### General Prerequisites

Most projects require some combination of:
- **Docker** and **Docker Compose** (for containerized deployments)
- **Terraform** >= 1.0 (for infrastructure as code)
- **Cloud CLI tools** (AWS CLI, Azure CLI) with appropriate credentials
- **Packer** (for VM image building)
- **Git** (for version control)

### Repository Structure

```
devops/
├── aws/              # AWS auto-scaling infrastructure
├── azure/            # Azure IaC with CI/CD pipelines
├── packer/           # Linux VM image builder
├── vault/            # HashiCorp Vault secrets management
├── legacy-kvm/       # Legacy KVM/IPMI access tool
├── LICENSE           # MIT License for all projects
└── README.md         # This file
```

## Documentation Standards

Each project includes:
- **README.md** - Comprehensive project documentation
- **Configuration examples** - Sample files for easy setup
- **Security guidelines** - Best practices and considerations
- **Troubleshooting** - Common issues and solutions

## Technology Stack

This repository demonstrates expertise across:

**Cloud Platforms:**
- Amazon Web Services (AWS)
- Microsoft Azure
- VMware Cloud Director

**Infrastructure as Code:**
- Terraform
- Packer
- Docker Compose

**Container Orchestration:**
- Kubernetes (AKS)
- Docker
- ArgoCD GitOps

**Monitoring & Observability:**
- Prometheus
- Grafana
- AlertManager

**CI/CD:**
- Azure DevOps Pipelines
- AWS CodeDeploy
- GitOps workflows

**Secrets Management:**
- HashiCorp Vault

## Security

All projects follow security best practices:
- No hardcoded credentials in version control
- Templating engines for sensitive data
- SSH key-based authentication where applicable
- Network security group configurations
- IAM/RBAC least-privilege access
- Secrets management integration

See individual project documentation and [packer/SECURITY.md](./packer/SECURITY.md) for detailed security guidelines.

## License

This repository and all subprojects are licensed under the MIT License.

Copyright (c) 2025 Serhii Nesterenko

See [LICENSE](./LICENSE) file for full license text.

## Author

**Serhii Nesterenko**

## Contributing

Contributions are welcome! Each project is designed for educational and production use. Feel free to:
- Open issues for bugs or questions
- Submit pull requests for improvements
- Fork projects for your own use cases
- Share feedback and suggestions

## Use Cases

### For Learning
- Study modern DevOps practices across multiple platforms
- Understand infrastructure automation patterns
- Learn Terraform, Kubernetes, and container orchestration
- Explore monitoring and observability solutions

### For Production
- Deploy cost-effective auto-scaling infrastructure
- Implement enterprise CI/CD pipelines
- Build consistent VM templates
- Manage secrets securely
- Access legacy hardware remotely

## Support

For questions, issues, or contributions, please open a GitHub issue in this repository.

---

**Last Updated:** 2025
