# Vault Integration Examples

This directory contains practical examples for integrating HashiCorp Vault with various languages and tools.

## Available Examples

### 1. Policy Configuration
- **File**: `deployment-policy.hcl`
- **Description**: Example Vault policy for deployment access
- **Usage**:
  ```bash
  vault policy write deployment deployment-policy.hcl
  vault token create -policy=deployment -ttl=720h
  ```

### 2. envconsul Configuration
- **File**: `envconsul.hcl`
- **Description**: Configuration for envconsul to populate environment variables from Vault
- **Usage**:
  ```bash
  envconsul -config=envconsul.hcl -secret kv/dev/myapp -no-prefix ./your-app
  ```

### 3. Python Integration
- **File**: `python-vault-client.py`
- **Description**: Complete Python example using hvac library
- **Requirements**: `pip install hvac`
- **Usage**:
  ```bash
  export VAULT_TOKEN=your_token
  python python-vault-client.py
  ```

### 4. Bash Integration
- **File**: `bash-integration.sh`
- **Description**: Shell script examples for Vault operations
- **Requirements**: `curl`, `jq`
- **Usage**:
  ```bash
  chmod +x bash-integration.sh
  VAULT_TOKEN=your_token ./bash-integration.sh
  ```

### 5. Node.js Integration
- **File**: `nodejs-vault-client.js`
- **Description**: Node.js examples using node-vault library
- **Requirements**: `npm install node-vault`
- **Usage**:
  ```bash
  export VAULT_TOKEN=your_token
  node nodejs-vault-client.js
  ```

### 6. Docker Compose Integration
- **File**: `docker-compose-example.yml`
- **Description**: Multi-container setup with Vault integration
- **Usage**:
  ```bash
  export VAULT_TOKEN=your_token
  docker-compose -f docker-compose-example.yml up
  ```

## Quick Start

1. **Start Vault** (if not already running):
   ```bash
   cd ..
   docker-compose up -d
   ```

2. **Initialize Vault** and get your token:
   ```bash
   export VAULT_ADDR=http://localhost:8200
   export VAULT_TOKEN=your_root_token
   ```

3. **Enable KV secrets engine** (if not already enabled):
   ```bash
   vault secrets enable -version=1 -path=kv kv
   ```

4. **Run any example**:
   ```bash
   # Python
   python python-vault-client.py

   # Bash
   ./bash-integration.sh

   # Node.js
   node nodejs-vault-client.js
   ```

## Environment Variables

All examples use these common environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `VAULT_ADDR` | Vault server address | `http://localhost:8200` |
| `VAULT_TOKEN` | Authentication token | (required) |
| `ENVIRONMENT` | Target environment | `dev` |
| `APP_NAME` | Application name | `myapp` |

## Common Operations

### Store Secrets
```bash
# Using CLI
vault kv put kv/dev/myapp \
  DATABASE_URL="postgres://localhost/db" \
  API_KEY="key123"

# Using curl
curl -H "X-Vault-Token: $VAULT_TOKEN" \
  -X POST \
  -d '{"DATABASE_URL":"postgres://localhost/db","API_KEY":"key123"}' \
  http://localhost:8200/v1/kv/dev/myapp
```

### Read Secrets
```bash
# Using CLI
vault kv get kv/dev/myapp

# Using curl
curl -H "X-Vault-Token: $VAULT_TOKEN" \
  http://localhost:8200/v1/kv/dev/myapp
```

### List Secrets
```bash
# Using CLI
vault kv list kv/dev

# Using curl
curl -X LIST -H "X-Vault-Token: $VAULT_TOKEN" \
  http://localhost:8200/v1/kv/dev
```

## Integration Patterns

### Pattern 1: Direct API Access
Applications make direct HTTP calls to Vault API.
- **Pros**: Simple, no additional tools
- **Cons**: Requires Vault client library or HTTP client

### Pattern 2: envconsul
Use envconsul to populate environment variables.
- **Pros**: Transparent to application, automatic updates
- **Cons**: Additional process to manage

### Pattern 3: Init Container (Kubernetes)
Fetch secrets in init container, write to shared volume.
- **Pros**: Works with legacy applications
- **Cons**: Secrets not automatically updated

### Pattern 4: Vault Agent
Run Vault Agent sidecar to handle authentication and secret retrieval.
- **Pros**: Advanced features, automatic renewal
- **Cons**: More complex setup

## Best Practices

1. **Never hardcode tokens** - Use environment variables
2. **Use appropriate TTLs** - Short-lived tokens for security
3. **Implement retry logic** - Handle Vault unavailability
4. **Secure token storage** - Use secure methods to pass tokens
5. **Use policies** - Least privilege access
6. **Enable audit logging** - Track secret access
7. **Rotate secrets regularly** - Update credentials periodically

## Troubleshooting

### "Permission denied" errors
- Check your token has the correct policy
- Verify the policy has read access to the path
- Ensure the path exists

### "Connection refused"
- Verify Vault is running: `docker ps`
- Check VAULT_ADDR is correct
- Ensure firewall allows connections

### "Vault is sealed"
- Unseal Vault: `vault operator unseal`
- Check auto-unseal configuration
- Verify keys.txt is mounted correctly

## Additional Resources

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault API Reference](https://developer.hashicorp.com/vault/api-docs)
- [hvac Python Client](https://hvac.readthedocs.io/)
- [node-vault Client](https://www.npmjs.com/package/node-vault)
- [envconsul](https://github.com/hashicorp/envconsul)

---

Copyright (c) 2025 Serhii Nesterenko
