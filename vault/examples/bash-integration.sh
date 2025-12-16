#!/bin/bash
# Example: Integrating Vault with Bash scripts

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
APP_NAME="${APP_NAME:-myapp}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check dependencies
check_dependencies() {
    local deps=("curl" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}Error: $dep is not installed${NC}"
            exit 1
        fi
    done
}

# Check if Vault token is set
check_token() {
    if [ -z "$VAULT_TOKEN" ]; then
        echo -e "${RED}Error: VAULT_TOKEN environment variable is not set${NC}"
        echo "Usage: VAULT_TOKEN=your_token $0"
        exit 1
    fi
}

# Fetch secret from Vault
fetch_secret() {
    local secret_path="$1"
    local response

    response=$(curl -s -H "X-Vault-Token: ${VAULT_TOKEN}" \
        "${VAULT_ADDR}/v1/${secret_path}")

    # Check if request was successful
    if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
        echo -e "${RED}Error fetching secret:${NC}"
        echo "$response" | jq -r '.errors[]'
        return 1
    fi

    echo "$response"
}

# Extract value from secret response
get_secret_value() {
    local secret_path="$1"
    local key="$2"
    local response

    response=$(fetch_secret "$secret_path")
    echo "$response" | jq -r ".data.${key} // empty"
}

# Load all secrets from path into environment variables
load_secrets_to_env() {
    local secret_path="$1"
    local response

    echo -e "${YELLOW}Loading secrets from ${secret_path}...${NC}"

    response=$(fetch_secret "$secret_path")

    # Export all key-value pairs as environment variables
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            export "$key=$value"
            echo -e "${GREEN}✓${NC} Loaded: $key"
        fi
    done < <(echo "$response" | jq -r '.data | to_entries | .[] | "\(.key)=\(.value)"')
}

# Write secret to Vault
write_secret() {
    local secret_path="$1"
    shift
    local data="{}"

    # Build JSON data from key=value pairs
    for pair in "$@"; do
        local key="${pair%%=*}"
        local value="${pair#*=}"
        data=$(echo "$data" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
    done

    local response
    response=$(curl -s -X POST \
        -H "X-Vault-Token: ${VAULT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${VAULT_ADDR}/v1/${secret_path}")

    # Check if request was successful
    if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
        echo -e "${RED}Error writing secret:${NC}"
        echo "$response" | jq -r '.errors[]'
        return 1
    fi

    echo -e "${GREEN}✓${NC} Successfully wrote secret to ${secret_path}"
}

# List secrets at a path
list_secrets() {
    local secret_path="$1"
    local response

    response=$(curl -s -X LIST \
        -H "X-Vault-Token: ${VAULT_TOKEN}" \
        "${VAULT_ADDR}/v1/${secret_path}")

    # Check if request was successful
    if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
        echo -e "${RED}Error listing secrets:${NC}"
        echo "$response" | jq -r '.errors[]'
        return 1
    fi

    echo "$response" | jq -r '.data.keys[]?'
}

# Example usage
example_usage() {
    echo -e "${YELLOW}=== Vault Bash Integration Examples ===${NC}\n"

    # Example 1: Write secrets
    echo -e "${YELLOW}Example 1: Writing secrets...${NC}"
    write_secret "kv/${ENVIRONMENT}/${APP_NAME}" \
        "DATABASE_URL=postgres://localhost:5432/myapp" \
        "API_KEY=test-api-key-123" \
        "SECRET_KEY=test-secret-key-456"
    echo

    # Example 2: Read specific value
    echo -e "${YELLOW}Example 2: Reading specific secret value...${NC}"
    db_url=$(get_secret_value "kv/${ENVIRONMENT}/${APP_NAME}" "DATABASE_URL")
    echo -e "${GREEN}Database URL:${NC} $db_url"
    echo

    # Example 3: Load all secrets to environment
    echo -e "${YELLOW}Example 3: Loading all secrets to environment...${NC}"
    load_secrets_to_env "kv/${ENVIRONMENT}/${APP_NAME}"
    echo

    # Example 4: List secrets
    echo -e "${YELLOW}Example 4: Listing secrets in kv/${ENVIRONMENT}/...${NC}"
    list_secrets "kv/${ENVIRONMENT}" || echo "No secrets found"
    echo

    # Example 5: Use secrets in application
    echo -e "${YELLOW}Example 5: Using secrets in your application...${NC}"
    echo "DATABASE_URL is now: ${DATABASE_URL:-not set}"
    echo "API_KEY is now: ${API_KEY:-not set}"
    echo
}

# Main
main() {
    check_dependencies
    check_token
    example_usage

    echo -e "${GREEN}All examples completed successfully!${NC}"
    echo -e "\n${YELLOW}Note:${NC} Environment variables are only available in this shell session."
    echo "To use them in your application, source this script or use envconsul."
}

# Run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
