# Deployment Policy for Vault
# This policy allows read-only access to secrets in dev, staging, and prod environments
# Usage: vault policy write deployment deployment-policy.hcl

# Allow reading secrets from dev environment
path "kv/dev/*" {
  capabilities = ["read", "list"]
}

# Allow reading secrets from staging environment
path "kv/staging/*" {
  capabilities = ["read", "list"]
}

# Allow reading secrets from prod environment
path "kv/prod/*" {
  capabilities = ["read", "list"]
}

# Deny access to sensitive paths
path "sys/auth/*" {
  capabilities = ["deny"]
}

path "sys/policies/*" {
  capabilities = ["deny"]
}
