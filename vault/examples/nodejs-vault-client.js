#!/usr/bin/env node
/**
 * Example: Using HashiCorp Vault with Node.js
 * Install dependencies: npm install node-vault
 */

const vault = require('node-vault');

// Configuration
const VAULT_ADDR = process.env.VAULT_ADDR || 'http://localhost:8200';
const VAULT_TOKEN = process.env.VAULT_TOKEN;
const ENVIRONMENT = process.env.ENVIRONMENT || 'dev';
const APP_NAME = process.env.APP_NAME || 'myapp';

class VaultClient {
  constructor(endpoint, token) {
    if (!token) {
      throw new Error('VAULT_TOKEN environment variable is required');
    }

    this.client = vault({
      apiVersion: 'v1',
      endpoint: endpoint,
      token: token
    });
  }

  /**
   * Read secret from KV v1 store
   * @param {string} path - Secret path (e.g., 'kv/dev/myapp')
   * @returns {Promise<Object>} Secret data
   */
  async readSecret(path) {
    try {
      const result = await this.client.read(path);
      return result.data;
    } catch (error) {
      console.error(`Error reading secret from ${path}:`, error.message);
      throw error;
    }
  }

  /**
   * Write secret to KV v1 store
   * @param {string} path - Secret path
   * @param {Object} data - Key-value pairs to store
   */
  async writeSecret(path, data) {
    try {
      await this.client.write(path, data);
      console.log(`✓ Successfully wrote secret to ${path}`);
    } catch (error) {
      console.error(`Error writing secret to ${path}:`, error.message);
      throw error;
    }
  }

  /**
   * List secrets at a given path
   * @param {string} path - Path to list
   * @returns {Promise<Array>} List of secret names
   */
  async listSecrets(path) {
    try {
      const result = await this.client.list(path);
      return result.data.keys || [];
    } catch (error) {
      console.error(`Error listing secrets at ${path}:`, error.message);
      return [];
    }
  }

  /**
   * Delete a secret
   * @param {string} path - Secret path to delete
   */
  async deleteSecret(path) {
    try {
      await this.client.delete(path);
      console.log(`✓ Successfully deleted secret at ${path}`);
    } catch (error) {
      console.error(`Error deleting secret at ${path}:`, error.message);
      throw error;
    }
  }
}

/**
 * Example usage
 */
async function main() {
  console.log('=== Vault Node.js Client Examples ===\n');

  // Initialize client
  const vaultClient = new VaultClient(VAULT_ADDR, VAULT_TOKEN);
  const secretPath = `kv/${ENVIRONMENT}/${APP_NAME}`;

  try {
    // Example 1: Write secrets
    console.log('Example 1: Writing secrets...');
    await vaultClient.writeSecret(secretPath, {
      DATABASE_URL: 'postgres://localhost:5432/myapp',
      API_KEY: 'nodejs-api-key-123',
      SECRET_KEY: 'nodejs-secret-key-456',
      REDIS_URL: 'redis://localhost:6379'
    });
    console.log();

    // Example 2: Read secrets
    console.log('Example 2: Reading secrets...');
    const secrets = await vaultClient.readSecret(secretPath);
    console.log('Database URL:', secrets.DATABASE_URL);
    console.log('API Key:', secrets.API_KEY.substring(0, 10) + '...');
    console.log();

    // Example 3: List secrets
    console.log('Example 3: Listing secrets...');
    const secretList = await vaultClient.listSecrets(`kv/${ENVIRONMENT}`);
    console.log(`Secrets in kv/${ENVIRONMENT}:`, secretList);
    console.log();

    // Example 4: Use secrets in your application
    console.log('Example 4: Using secrets in application config...');
    const appConfig = {
      database: {
        url: secrets.DATABASE_URL
      },
      api: {
        key: secrets.API_KEY
      },
      redis: {
        url: secrets.REDIS_URL
      }
    };
    console.log('App configuration loaded from Vault:');
    console.log(JSON.stringify(appConfig, null, 2));
    console.log();

    // Example 5: Environment-specific configuration
    console.log('Example 5: Loading environment-specific config...');
    const envConfig = await loadEnvironmentConfig(vaultClient, ENVIRONMENT);
    console.log('Environment configuration:', envConfig);

    console.log('\n✓ All examples completed successfully!');
  } catch (error) {
    console.error('\n✗ Error running examples:', error.message);
    process.exit(1);
  }
}

/**
 * Load configuration for a specific environment
 * @param {VaultClient} client - Vault client instance
 * @param {string} env - Environment name (dev, staging, prod)
 * @returns {Promise<Object>} Environment configuration
 */
async function loadEnvironmentConfig(client, env) {
  const apps = ['webapp', 'api', 'worker'];
  const config = {};

  for (const app of apps) {
    try {
      const secrets = await client.readSecret(`kv/${env}/${app}`);
      config[app] = secrets;
    } catch (error) {
      console.log(`  No secrets found for ${app} in ${env} environment`);
    }
  }

  return config;
}

/**
 * Export secrets as environment variables
 * @param {Object} secrets - Secret key-value pairs
 */
function exportToEnvironment(secrets) {
  for (const [key, value] of Object.entries(secrets)) {
    process.env[key] = value;
    console.log(`✓ Exported ${key} to environment`);
  }
}

// Run if executed directly
if (require.main === module) {
  main().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = { VaultClient, exportToEnvironment };
