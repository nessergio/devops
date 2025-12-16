# envconsul Configuration
# Place this file at ~/.envconsul.hcl or /etc/envconsul.hcl

# Don't uppercase environment variable names
upcase = false

# Vault configuration
vault {
  # Vault server address
  address = "http://localhost:8200"

  # Vault token (replace with your actual token)
  # In production, use environment variable: VAULT_TOKEN
  token = "YOUR_VAULT_TOKEN_HERE"

  # Enable retries for connection failures
  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
    max_backoff = "1m"
  }

  # SSL configuration (if using HTTPS)
  ssl {
    enabled = false
    verify = true
    # cert = "/path/to/client/cert.pem"
    # ca_cert = "/path/to/ca/cert.pem"
  }
}

# Optional: Kill signal to send when config changes
kill_signal = "SIGTERM"

# Optional: Reload signal to send when config changes
reload_signal = "SIGHUP"

# Optional: Splay to add jitter
splay = "5s"

# Optional: Deduplicate environment variables
deduplicate {
  enabled = true
  prefix = "vault"
}
