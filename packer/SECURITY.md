# Security Guidelines

## Overview

This document outlines security best practices for managing Packer configurations and credentials in this repository.

## Credential Management

### What NOT to Commit

The following files contain sensitive information and must NEVER be committed to version control:

- `*.auto.tfvars` - Terraform variable files with credentials
- `*.auto.pkrvars.hcl` - Packer variable files with credentials
- `vcd.tf` - Terraform provider configuration (may contain hardcoded credentials)
- `variables.*.hcl` - Specific variable files with passwords
- `terraform.tfstate*` - Terraform state files (may contain sensitive data)
- `.terraform/` - Terraform plugins and cached data

### What to Use Instead

Always use the example files as templates:

1. **For Packer variables**:
   ```bash
   cp variables.example.hcl variables.auto.pkrvars.hcl
   # Edit variables.auto.pkrvars.hcl with your credentials
   ```

2. **For Terraform VCD**:
   ```bash
   cp vcd.tf.example vcd.tf
   cp vcd.auto.tfvars.example vcd.auto.tfvars
   # Edit both files with your credentials
   ```

## Password Security

### SSH Passwords

- **Never use default passwords** like "adminadmin" in production
- Use **strong, unique passwords** (minimum 16 characters)
- Consider using **SSH keys** instead of passwords when possible
- Rotate passwords regularly

### VCD/Cloud Credentials

- Use **API tokens** instead of passwords when possible
- Enable **MFA/2FA** on cloud accounts
- Follow the **principle of least privilege**
- Create **service accounts** for automation (don't use personal accounts)
- Rotate credentials every 90 days

## .gitignore Protection

The `.gitignore` file is configured to prevent accidental commits of sensitive files:

```gitignore
# Credentials and secrets
*.auto.tfvars
*.auto.pkrvars.hcl
vcd.tf
variables.*.hcl
!variables.example.hcl
```

### Verification

Before committing, always verify no secrets are staged:

```bash
git status
git diff --cached
```

## Environment Variables

For CI/CD pipelines, use environment variables instead of files:

```bash
export PKR_VAR_ssh_password="your-password"
export PKR_VAR_ssh_username="your-username"
packer build ubuntu.pkr.hcl
```

Terraform variables:

```bash
export TF_VAR_vcd_user="your-username"
export TF_VAR_vcd_pass="your-password"
terraform apply
```

## Secrets Management Solutions

For production environments, consider using:

- **HashiCorp Vault** - Centralized secrets management
- **AWS Secrets Manager** - For AWS environments
- **Azure Key Vault** - For Azure environments
- **Google Secret Manager** - For GCP environments
- **CyberArk** or **1Password** - Enterprise password managers

## Build Artifact Security

### Output Files

Packer build outputs may contain sensitive information:

- OVA files are stored in `output*/` directories
- These are gitignored but should be:
  - Stored securely
  - Encrypted at rest
  - Access controlled
  - Not shared publicly

### State Files

Terraform state files contain:

- Resource IDs
- IP addresses
- Potentially credentials

**Best practices**:

- Use **remote state** backends (S3, Azure Storage, Terraform Cloud)
- Enable **state encryption**
- Enable **state locking**
- Never commit state files to git

## Code Review Checklist

Before committing changes, verify:

- [ ] No hardcoded credentials in any files
- [ ] All sensitive files are in `.gitignore`
- [ ] Example files are updated if needed
- [ ] No API keys or tokens in code
- [ ] No IP addresses or internal hostnames
- [ ] No organization-specific information
- [ ] `git status` shows only intended files

## Incident Response

### If Credentials are Committed

1. **Immediately rotate** all exposed credentials
2. **Remove from git history**:
   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch path/to/secret/file' \
     --prune-empty --tag-name-filter cat -- --all
   git push origin --force --all
   ```
3. **Notify security team** if applicable
4. **Review access logs** for unauthorized usage
5. **Update documentation** to prevent recurrence

### If Secrets are Exposed Publicly

1. **Rotate credentials immediately**
2. **Remove the repository** if it's a public fork
3. **Contact GitHub support** to purge cached content
4. **Monitor for unauthorized access**
5. **Consider all exposed credentials compromised**

## Compliance Requirements

Depending on your industry, you may need to comply with:

- **PCI DSS** - Payment card data security
- **HIPAA** - Healthcare data protection
- **GDPR** - European data protection
- **SOC 2** - Service organization controls
- **ISO 27001** - Information security management

Ensure your credential management practices align with applicable regulations.

## Regular Audits

Perform regular security audits:

- **Weekly**: Review new commits for exposed secrets
- **Monthly**: Rotate credentials and review access logs
- **Quarterly**: Full security review and penetration testing
- **Annually**: Third-party security assessment

## Tools

Consider using automated tools to prevent secret leaks:

- **git-secrets** - Prevents committing secrets
- **truffleHog** - Scans for high entropy strings
- **detect-secrets** - Prevents new secrets in codebase
- **GitHub Secret Scanning** - Automatic scanning (if enabled)
- **pre-commit hooks** - Client-side validation

## Contact

For security concerns or incidents, please open a GitHub issue or contact the repository maintainer.

---

Copyright (c) 2025 Serhii Nesterenko
