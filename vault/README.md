# HashiCorp Vault Docker Setup

A containerized HashiCorp Vault deployment for secure secrets management across different environments (dev/staging/prod).

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Examples](#examples)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Useful Links](#useful-links)

## Overview

This project provides a production-ready HashiCorp Vault setup using Docker, featuring:
- Automatic unsealing on startup
- Raft storage backend for high availability
- Cluster support with multiple nodes
- Persistent data storage
- Web UI enabled

## Features

- **Automated Unsealing**: Vault automatically unseals on container startup
- **Raft Storage**: Built-in integrated storage for HA deployments
- **Cluster Support**: Multi-node deployment with automatic leader election
- **Docker-based**: Easy deployment and management
- **Persistent Storage**: Data persisted via Docker volumes
- **Web UI**: User-friendly interface at port 8200

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- At least 512MB RAM available
- Network access for cluster communication (ports 8200, 8201)

## Installation

### 1. Clone and Build

```bash
# Navigate to the vault directory
cd /path/to/vault

# Build the Docker image
docker build -t vault:latest .

# Or use docker-compose to build
docker-compose build
```

### 2. Prepare Configuration

Edit `config/vault.hcl` to match your environment:

```hcl
storage "raft" {
  path = "/vault/data"
  node_id = "vault-node-1"  # Change this for each node

  retry_join {
    leader_api_addr = "http://LEADER_IP:8200"
  }
}

cluster_addr = "http://YOUR_IP:8201"
api_addr = "http://YOUR_IP:8200"

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = true  # Set to false in production with proper TLS
}
```

### 3. Start Vault

```bash
docker-compose up -d
```

## Configuration

### Initial Setup

1. **Access the UI**
   - Navigate to `http://{server-ip}:8200`
   - Complete the initialization wizard

2. **Initialize Vault**
   - Choose key shares (e.g., 5 shares with threshold of 3)
   - **IMPORTANT**: Save all unseal keys and root token securely
   - Store keys in a secure location (password manager, secrets vault, etc.)

3. **Configure Automatic Unsealing**

   Create a `keys.txt` file with your unseal keys (one per line):
   ```
   unseal_key_1
   unseal_key_2
   unseal_key_3
   ```

   Mount it to the container:
   ```yaml
   # Add to docker-compose.yml volumes
   volumes:
     - ~/vault/data:/vault/data
     - ~/vault/config:/vault/config
     - ~/vault/keys.txt:/keys.txt  # Add this line
   ```

4. **Create KV Store**
   ```bash
   # Using Vault CLI
   vault secrets enable -version=1 -path=kv kv

   # Or via UI: Enable new engine > KV > Version 1
   ```

5. **Create Environment Folders**
   ```bash
   # Create paths for each environment
   vault kv put kv/dev/.gitkeep value=placeholder
   vault kv put kv/staging/.gitkeep value=placeholder
   vault kv put kv/prod/.gitkeep value=placeholder
   ```

### Setting Up Policies

Create a deployment policy for read-only access:

```bash
# Create policy file: deployment-policy.hcl
cat > deployment-policy.hcl <<EOF
path "kv/dev/*" {
  capabilities = ["read", "list"]
}

path "kv/staging/*" {
  capabilities = ["read", "list"]
}

path "kv/prod/*" {
  capabilities = ["read", "list"]
}
EOF

# Apply the policy
vault policy write deployment deployment-policy.hcl

# Create a token with this policy
vault token create -policy=deployment -ttl=720h
```

## Usage

### Storing Secrets

#### Via CLI
```bash
# Store application secrets as JSON
vault kv put kv/dev/myapp \
  DATABASE_URL="postgres://localhost/myapp" \
  API_KEY="your-api-key" \
  SECRET_KEY="your-secret-key"
```

#### Via UI
1. Navigate to `http://{server-ip}:8200`
2. Go to Secrets > kv
3. Click "Create secret"
4. Path: `dev/myapp`
5. Add key-value pairs
6. Save

### Reading Secrets

#### Via CLI
```bash
# Read all secrets for an app
vault kv get kv/dev/myapp

# Get specific field
vault kv get -field=DATABASE_URL kv/dev/myapp
```

#### Via API
```bash
curl -H "X-Vault-Token: YOUR_TOKEN" \
  http://localhost:8200/v1/kv/dev/myapp
```

### Token Management

```bash
# Create a new token
vault token create -policy=deployment -ttl=720h

# Renew a token
vault token renew YOUR_TOKEN

# Revoke a token
vault token revoke YOUR_TOKEN

# Check token info
vault token lookup YOUR_TOKEN
```

## Examples

### Example 1: Using with envconsul

`envconsul` automatically populates environment variables from Vault.

**Configuration** (`~/envconsul.hcl`):
```hcl
upcase = false

vault {
  address = "http://localhost:8200"
  token = "YOUR_VAULT_TOKEN_HERE"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }
}
```

**Usage**:
```bash
# Run application with secrets as environment variables
envconsul -config='/home/user/envconsul.hcl' \
  -secret kv/dev/myapp \
  -no-prefix \
  ./my-application

# Test: View environment variables
envconsul -config='/home/user/envconsul.hcl' \
  -secret kv/dev/myapp \
  -no-prefix \
  env | grep -E 'DATABASE|API_KEY'
```

### Example 2: Python Application

```python
import hvac
import os

# Initialize Vault client
client = hvac.Client(
    url='http://localhost:8200',
    token=os.environ['VAULT_TOKEN']
)

# Read secrets
secret_path = 'kv/dev/myapp'
secrets = client.secrets.kv.v1.read_secret(path=secret_path)

# Access secret values
database_url = secrets['data']['DATABASE_URL']
api_key = secrets['data']['API_KEY']

print(f"Database URL: {database_url}")
```

### Example 3: Docker Compose Integration

```yaml
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: ${VAULT_TOKEN}
    depends_on:
      - vault
    command: >
      sh -c "
        apk add curl jq &&
        export $(curl -H 'X-Vault-Token: ${VAULT_TOKEN}'
          http://vault:8200/v1/kv/dev/myapp |
          jq -r '.data | to_entries | .[] | .key + \"=\" + .value') &&
        ./start-app.sh
      "

  vault:
    image: vault:latest
    ports:
      - "8200:8200"
    volumes:
      - ./vault/data:/vault/data
      - ./vault/config:/vault/config
```

### Example 4: Bash Script Integration

```bash
#!/bin/bash

VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="your-token-here"
SECRET_PATH="kv/dev/myapp"

# Fetch secrets
response=$(curl -s -H "X-Vault-Token: ${VAULT_TOKEN}" \
  "${VAULT_ADDR}/v1/${SECRET_PATH}")

# Extract specific values
DATABASE_URL=$(echo "$response" | jq -r '.data.DATABASE_URL')
API_KEY=$(echo "$response" | jq -r '.data.API_KEY')

# Export as environment variables
export DATABASE_URL
export API_KEY

# Run your application
./my-application
```

### Example 5: Multi-Environment Setup

```bash
# Development environment
vault kv put kv/dev/webapp \
  DATABASE_URL="postgres://dev-db:5432/webapp" \
  DEBUG="true" \
  LOG_LEVEL="debug"

# Staging environment
vault kv put kv/staging/webapp \
  DATABASE_URL="postgres://staging-db:5432/webapp" \
  DEBUG="false" \
  LOG_LEVEL="info"

# Production environment
vault kv put kv/prod/webapp \
  DATABASE_URL="postgres://prod-db:5432/webapp" \
  DEBUG="false" \
  LOG_LEVEL="warning"

# Application reads based on ENVIRONMENT variable
envconsul -config='envconsul.hcl' \
  -secret "kv/${ENVIRONMENT}/webapp" \
  -no-prefix \
  ./webapp
```

## Security Best Practices

### 1. Unseal Keys
- **Never** commit `keys.txt` to version control (already in `.gitignore`)
- Store unseal keys in separate secure locations
- Use Shamir's secret sharing (e.g., 5 keys with threshold of 3)
- Distribute keys among different trusted personnel

### 2. Root Token
- Use the root token only for initial setup
- Revoke or secure the root token after setup
- Create specific policies for day-to-day operations
- Never hardcode tokens in application code

### 3. TLS/SSL
- **Enable TLS in production** (currently disabled in config)
- Use valid certificates from a trusted CA
- Configure `tls_disable = false` in `vault.hcl`
- Update clients to use `https://` URLs

### 4. Token Management
- Use short-lived tokens with appropriate TTL
- Implement token renewal for long-running services
- Revoke unused or compromised tokens immediately
- Use periodic tokens for enhanced security

### 5. Network Security
- Restrict network access to Vault ports (8200, 8201)
- Use firewall rules to allow only necessary IPs
- Consider running Vault in a private network
- Use VPN or SSH tunnels for remote access

### 6. Audit Logging
```bash
# Enable audit logging
vault audit enable file file_path=/vault/logs/audit.log
```

### 7. Regular Backups
```bash
# Backup Vault data
vault operator raft snapshot save backup.snap

# Restore from backup
vault operator raft snapshot restore backup.snap
```

## Troubleshooting

### Vault is Sealed
```bash
# Check status
vault status

# Manual unseal (requires threshold number of keys)
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

### Cannot Access UI
1. Check if container is running: `docker ps`
2. Check logs: `docker-compose logs vault`
3. Verify port mapping: `docker port <container_id> 8200`
4. Check firewall rules

### Cluster Issues
1. Verify network connectivity between nodes
2. Check `config/vault.hcl` for correct IP addresses
3. Ensure `node_id` is unique on each node
4. Review cluster status: `vault operator raft list-peers`

### Permission Denied Errors
1. Verify token has correct policy attached
2. Check policy capabilities for the requested path
3. Ensure policy is correctly applied to token

### Auto-unseal Not Working
1. Verify `/keys.txt` exists in container
2. Check unseal keys are correct (one per line)
3. Review container logs for unseal errors
4. Ensure file has proper line endings (LF, not CRLF)

## Useful Links

- [Official Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Getting Started with Vault UI](https://developer.hashicorp.com/vault/tutorials/getting-started-ui)
- [Vault API Documentation](https://developer.hashicorp.com/vault/api-docs)
- [Vault Policies Guide](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [envconsul Documentation](https://github.com/hashicorp/envconsul)
- [Production Hardening](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko
