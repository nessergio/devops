# Oracle Linux Packer Build

This directory contains the Packer configuration for building Oracle Linux virtual machine images.

## Quick Start

1. **Copy the variables file:**
   ```bash
   cp variables.example.hcl variables.auto.pkrvars.hcl
   ```

2. **Generate password hashes:**
   ```bash
   # For both root and user passwords
   python3 -c 'import crypt; print(crypt.crypt("your-password", crypt.mksalt(crypt.METHOD_SHA512)))'
   ```

3. **Edit variables.auto.pkrvars.hcl** with your configuration:
   - Set `root_password_hash` and `user_password_hash`
   - Add your SSH public key to `ssh_authorized_key`
   - Update ISO URL and checksum if needed

4. **Build the image:**
   ```bash
   packer init .
   packer validate -var-file=variables.auto.pkrvars.hcl .
   packer build -var-file=variables.auto.pkrvars.hcl .
   ```

## Configuration

- **Main Template**: `oracle-linux.pkr.hcl`
- **Kickstart Template**: `config/kickstart.cfg.pkrtpl.hcl`
- **Variables**: `variables.auto.pkrvars.hcl` (create from example)

## Key Features

- Uses Anaconda installer with Kickstart
- Templated kickstart configuration
- No hardcoded credentials
- Automated user creation with sudo access
- SSH key-based authentication
- Minimal package installation

## ISO Downloads

Get Oracle Linux ISOs from:
https://yum.oracle.com/oracle-linux-isos.html

## Default Settings

- **Default User**: `oracle`
- **VNC Port**: `5972`
- **Guest OS Type**: `oraclelinux-64`
- **Build Time**: ~20-30 minutes

## See Also

Refer to the main [README.md](../README.md) in the parent directory for complete documentation.

---

Copyright (c) 2025 Serhii Nesterenko
