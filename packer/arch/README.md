# Arch Linux Packer Build

This directory contains the Packer configuration for building Arch Linux virtual machine images.

## Quick Start

1. **Copy the variables file:**
   ```bash
   cp variables.example.hcl variables.auto.pkrvars.hcl
   ```

2. **Generate password hashes:**
   ```bash
   # For both root and user passwords
   mkpasswd -m sha-512
   # Or using Python
   python3 -c 'import crypt; print(crypt.crypt("your-password", crypt.mksalt(crypt.METHOD_SHA512)))'
   ```

3. **Edit variables.auto.pkrvars.hcl** with your configuration:
   - Set `root_password_hash` and `user_password_hash`
   - Add your SSH public key to `ssh_authorized_key`
   - Set `ssh_password` (used during build for root login)
   - Update ISO URL and checksum if needed

4. **Build the image:**
   ```bash
   packer init .
   packer validate -var-file=variables.auto.pkrvars.hcl .
   packer build -var-file=variables.auto.pkrvars.hcl .
   ```

## Configuration

- **Main Template**: `arch-linux.pkr.hcl`
- **Installation Script**: `config/install.sh.pkrtpl.hcl`
- **Variables**: `variables.auto.pkrvars.hcl` (create from example)

## Key Features

- Custom bash-based installation script
- Templated installation configuration
- No hardcoded credentials
- Automated user creation with sudo access
- SSH key-based authentication
- Minimal base system installation
- GRUB bootloader

## Installation Process

Arch Linux uses a unique two-stage build process:

1. **Stage 1**: Boot into live environment
   - Sets root password via boot_command
   - Starts SSH for Packer connection

2. **Stage 2**: Run installation script
   - Partitions disk (ext4 on /dev/sda)
   - Installs base system with pacstrap
   - Configures system in chroot
   - Installs GRUB bootloader
   - Creates user and sets up SSH keys
   - Reboots into installed system

## ISO Downloads

Get Arch Linux ISOs from:
https://archlinux.org/download/

**Note**: Arch is a rolling release, so use the latest ISO available.

## Default Settings

- **Default User**: `arch`
- **VNC Port**: `5974`
- **Guest OS Type**: `other5xlinux-64`
- **Build Time**: ~30-40 minutes (longer due to package compilation)
- **Partition Scheme**:
  - /dev/sda1: 512MB boot partition (ext4)
  - /dev/sda2: Remaining space for root (ext4)

## Customization

Edit `config/install.sh.pkrtpl.hcl` to customize:
- Partition layout
- Package selection (modify the `pacman -Sy --noconfirm` line)
- Timezone (default: UTC)
- Locale (default: en_US.UTF-8)
- Additional system configuration

## See Also

Refer to the main [README.md](../README.md) in the parent directory for complete documentation.

---

Copyright (c) 2025 Serhii Nesterenko
