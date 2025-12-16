#!/usr/bin/env python3
"""
Example: Using HashiCorp Vault with Python
Requires: pip install hvac
"""

import hvac
import os
import sys
from typing import Dict, Any


class VaultClient:
    """Simple Vault client wrapper"""

    def __init__(self, url: str = None, token: str = None):
        """
        Initialize Vault client

        Args:
            url: Vault server URL (default: env VAULT_ADDR or http://localhost:8200)
            token: Vault token (default: env VAULT_TOKEN)
        """
        self.url = url or os.getenv('VAULT_ADDR', 'http://localhost:8200')
        self.token = token or os.getenv('VAULT_TOKEN')

        if not self.token:
            raise ValueError("Vault token not provided. Set VAULT_TOKEN environment variable.")

        self.client = hvac.Client(url=self.url, token=self.token)

        if not self.client.is_authenticated():
            raise ValueError("Failed to authenticate with Vault")

    def read_secret(self, path: str) -> Dict[str, Any]:
        """
        Read a secret from KV v1 store

        Args:
            path: Secret path (e.g., 'kv/dev/myapp')

        Returns:
            Dictionary containing secret data
        """
        try:
            response = self.client.secrets.kv.v1.read_secret(path=path)
            return response['data']
        except Exception as e:
            print(f"Error reading secret from {path}: {e}", file=sys.stderr)
            raise

    def write_secret(self, path: str, data: Dict[str, str]) -> None:
        """
        Write a secret to KV v1 store

        Args:
            path: Secret path (e.g., 'kv/dev/myapp')
            data: Dictionary of key-value pairs to store
        """
        try:
            self.client.secrets.kv.v1.create_or_update_secret(
                path=path,
                secret=data
            )
            print(f"Successfully wrote secret to {path}")
        except Exception as e:
            print(f"Error writing secret to {path}: {e}", file=sys.stderr)
            raise

    def list_secrets(self, path: str) -> list:
        """
        List secrets at a given path

        Args:
            path: Path to list (e.g., 'kv/dev')

        Returns:
            List of secret names
        """
        try:
            response = self.client.secrets.kv.v1.list_secrets(path=path)
            return response['data']['keys']
        except Exception as e:
            print(f"Error listing secrets at {path}: {e}", file=sys.stderr)
            raise


def main():
    """Example usage"""

    # Initialize client
    vault = VaultClient()

    # Example 1: Write a secret
    print("Example 1: Writing a secret...")
    secret_data = {
        'DATABASE_URL': 'postgres://localhost/myapp',
        'API_KEY': 'my-api-key-123',
        'SECRET_KEY': 'my-secret-key-456'
    }
    vault.write_secret('kv/dev/example-app', secret_data)

    # Example 2: Read a secret
    print("\nExample 2: Reading a secret...")
    secrets = vault.read_secret('kv/dev/example-app')
    print(f"Database URL: {secrets['DATABASE_URL']}")
    print(f"API Key: {secrets['API_KEY'][:10]}...")  # Partial display for security

    # Example 3: List secrets in a path
    print("\nExample 3: Listing secrets...")
    try:
        secret_list = vault.list_secrets('kv/dev')
        print(f"Secrets in kv/dev: {secret_list}")
    except Exception:
        print("No secrets found or path doesn't exist")

    # Example 4: Use secrets as environment variables
    print("\nExample 4: Setting environment variables from secrets...")
    app_secrets = vault.read_secret('kv/dev/example-app')
    for key, value in app_secrets.items():
        os.environ[key] = value
        print(f"Set {key} environment variable")

    # Now your application can access these via os.getenv('DATABASE_URL'), etc.
    print(f"\nEnvironment DATABASE_URL: {os.getenv('DATABASE_URL')}")


if __name__ == '__main__':
    main()
