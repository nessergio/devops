# Full configuration options can be found at https://www.vaultproject.io/docs/configuration

ui = true
disable_mlock = true

storage "raft" {
  path = "/vault/data"
  # Unique identifier for this node in the cluster
  # Replace with a unique name for each Vault server (e.g., "vault-node-1", "vault-node-2")
  node_id = "vault-node-1"

  # Cluster nodes to join (for HA setup)
  # Add retry_join blocks for each cluster member
  # Replace the IP addresses with your actual Vault server IPs
  retry_join {
    leader_api_addr = "http://192.168.1.10:8200"  # Example: First cluster node
  }
  retry_join {
    leader_api_addr = "http://192.168.1.11:8200"  # Example: Second cluster node
  }
}

# Cluster address for this node - used for internal cluster communication
# Replace with this server's IP address and cluster port (default: 8201)
cluster_addr = "http://192.168.1.10:8201"

# API address for this node - used for client communication
# Replace with this server's IP address and API port (default: 8200)
api_addr = "http://192.168.1.10:8200"

listener "tcp" {
  address       = "0.0.0.0:8200"
  # WARNING: TLS is disabled for development only
  # For production, set tls_disable = false and configure TLS certificates
  tls_disable   = true
}
