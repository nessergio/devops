# Ubuntu Server Packer Build

This directory contains the Packer configuration for building Ubuntu Server virtual machine images.

## Quick Start

1. **Copy the variables file:**
   ```bash
   cp variables.example.hcl variables.auto.pkrvars.hcl
   ```

2. **Generate password hash:**
   ```bash
   # Ubuntu requires SHA-512 with rounds parameter
   mkpasswd -m sha-512 -R 4096

   # Or using Python
   python3 -c 'import crypt; print(crypt.crypt("your-password", crypt.mksalt(crypt.METHOD_SHA512, rounds=4096)))'
   ```

3. **Edit variables.auto.pkrvars.hcl** with your configuration:
   - Set `password_hash` (must include rounds parameter)
   - Add your SSH public key to `ssh_authorized_key`
   - Update ISO URL and checksum if needed

4. **Build the image:**
   ```bash
   packer init .
   packer validate -var-file=variables.auto.pkrvars.hcl .
   packer build -var-file=variables.auto.pkrvars.hcl .
   ```

## Configuration

- **Main Template**: `ubuntu.pkr.hcl`
- **Cloud-init Template**: `config/user-data.pkrtpl.hcl`
- **Variables**: `variables.auto.pkrvars.hcl` (create from example)

## Key Features

- Uses Ubuntu autoinstall with cloud-init
- Templated cloud-init configuration
- No hardcoded credentials
- Automated user creation with sudo access
- SSH key-based authentication
- Minimal package installation
- VMware open-vm-tools support

## ISO Downloads

Get Ubuntu Server ISOs from:
https://ubuntu.com/download/server

**Popular versions:**
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 24.04 LTS (Noble Numbat)

## Default Settings

- **Default User**: `ubuntu`
- **VNC Port**: `5971`
- **Guest OS Type**: `ubuntu-64`
- **Build Time**: ~15-20 minutes

## Customization

### Modify Packages

Edit `config/user-data.pkrtpl.hcl` and update the `packages` section:

```yaml
packages:
  - open-vm-tools
  - cloud-init
  - your-package-here
```

### Add Post-Install Scripts

Add scripts to the `shell_scripts` variable in `variables.auto.pkrvars.hcl`:

```hcl
shell_scripts = ["./config/setup.sh", "./config/custom.sh"]
```

## See Also

Refer to the main [README.md](../README.md) in the parent directory for complete documentation.

---

Copyright (c) 2025 Serhii Nesterenko
