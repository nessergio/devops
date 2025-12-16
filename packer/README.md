# Packer Linux Image Builder

This repository contains Packer configurations for building Linux virtual machine images for VMware environments, including VMware Workstation and VMware Cloud Director (VCD).

## Overview

This project automates the creation of Linux virtual machine templates using HashiCorp Packer. It supports multiple Linux distributions:

### Supported Distributions

| Distribution | Directory | Installer | Default User |
|-------------|-----------|-----------|--------------|
| **Ubuntu Server** | `ubuntu/` | Cloud-init | `ubuntu` |
| **Oracle Linux** | `oracle/` | Kickstart | `oracle` |
| **Rocky Linux** | `rocky/` | Kickstart | `rocky` |
| **Arch Linux** | `arch/` | Custom Script | `arch` |

### Features

- **VMware Workstation/Fusion** (via vmware-iso builder)
- **VMware Cloud Director** deployment (via Terraform)
- **Templating engine** for secure credential management
- **Automated provisioning** with shell scripts
- **SSH key-based authentication**
- **No hardcoded credentials** in version control

## Prerequisites

### Required Software

1. **Packer** (v1.8.0 or later)

   **Linux (Debian/Ubuntu):**
   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install packer
   ```

   **macOS:**
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/packer
   ```

   **Manual Installation:**
   - Download from: https://www.packer.io/downloads
   - Extract and add to PATH

2. **VMware Workstation** or **VMware Fusion**
   - Required for building the base images
   - Ensure VMware is installed and licensed
   - Download from: https://www.vmware.com/products/workstation-pro.html

3. **whois** (for mkpasswd utility)

   **Linux (Debian/Ubuntu):**
   ```bash
   sudo apt install whois
   ```

   **macOS:**
   ```bash
   # mkpasswd is not available by default, use docker instead:
   # docker run -it --rm alpine mkpasswd -m sha-512
   ```

4. **Terraform** (optional, for VCD deployment)

   **Linux (Debian/Ubuntu):**
   ```bash
   sudo apt install terraform
   ```

   **macOS:**
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

### System Requirements

- **Disk Space**: At least 20GB free space for ISO downloads and build artifacts
- **Memory**: 4GB RAM minimum (8GB recommended for building)
- **Network**: Internet connection for downloading Ubuntu ISOs
- **CPU**: Hardware virtualization support (VT-x/AMD-V) enabled in BIOS

## Quick Start

### Choosing a Distribution

Each Linux distribution has its own directory with specific configuration files:

- **Ubuntu Server**: Navigate to `ubuntu/` directory
- **Oracle Linux**: Navigate to `oracle/` directory
- **Rocky Linux**: Navigate to `rocky/` directory
- **Arch Linux**: Navigate to `arch/` directory

The build process is similar for all distributions, with minor differences in configuration.

### 1. Clone the Repository

```bash
git clone <repository-url>
cd packer
```

Navigate to the appropriate distribution directory:
```bash
# For Ubuntu Server
cd ubuntu

# For Oracle Linux
cd oracle

# For Rocky Linux
cd rocky

# For Arch Linux
cd arch
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp variables.example.hcl variables.auto.pkrvars.hcl
```

#### Generate Password Hash

The password hash is used for the default user account in the VM image. The method varies by distribution:

**Ubuntu Server** (uses mkpasswd with rounds):
```bash
# Linux
mkpasswd -m sha-512 -R 4096

# macOS (using Docker)
docker run -it --rm alpine sh -c 'apk add --no-cache mkpasswd && mkpasswd -m sha-512 -R 4096'

# Python alternative
python3 -c 'import crypt; print(crypt.crypt("YOUR_PASSWORD", crypt.mksalt(crypt.METHOD_SHA512, rounds=4096)))'
```

**Oracle Linux, Rocky Linux, Arch Linux** (standard SHA-512):
```bash
# Linux
mkpasswd -m sha-512

# macOS (using Docker)
docker run -it --rm alpine sh -c 'apk add --no-cache mkpasswd && mkpasswd -m sha-512'

# Python alternative
python3 -c 'import crypt; print(crypt.crypt("YOUR_PASSWORD", crypt.mksalt(crypt.METHOD_SHA512)))'
```

**Note:**
- Oracle/Rocky/Arch require both `root_password_hash` and `user_password_hash`
- Ubuntu only requires `password_hash` for the default user

#### Add Your SSH Public Key

Generate an SSH key pair if you don't have one:

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or generate RSA key
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Copy your public key:

```bash
# Display your public key
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

#### Edit Configuration File

Edit `variables.auto.pkrvars.hcl` with your settings. Configuration differs by distribution:

**Ubuntu Server Example:**
```hcl
vm_name       = "ubuntu-server"
vm_cpu_cores  = 2
vm_mem_size   = 2048
vm_disk_size  = 102400
hostname      = "ubuntu-server"

ssh_username  = "ubuntu"
ssh_password  = "your-secure-password"

password_hash = "$6$rounds=4096$..."  # With rounds parameter
ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

iso_url      = "https://mirror.easyname.at/ubuntu-releases/22.04.3/ubuntu-22.04.3-live-server-amd64.iso"
iso_checksum = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"
```

**Oracle Linux / Rocky Linux Example:**
```hcl
vm_name       = "oracle-linux"  # or "rocky-linux"
vm_cpu_cores  = 2
vm_mem_size   = 2048
vm_disk_size  = 102400
hostname      = "oracle-linux"

ssh_username  = "oracle"  # or "rocky"
ssh_password  = "your-secure-password"

root_password_hash = "$6$..."  # Standard SHA-512 hash
user_password_hash = "$6$..."  # Standard SHA-512 hash
ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

iso_url      = "https://yum.oracle.com/ISOS/..."
iso_checksum = "sha256:..."
```

**Arch Linux Example:**
```hcl
vm_name       = "arch-linux"
vm_cpu_cores  = 2
vm_mem_size   = 2048
vm_disk_size  = 102400
hostname      = "arch-linux"

ssh_username  = "arch"
ssh_password  = "your-secure-password"

root_password_hash = "$6$..."
user_password_hash = "$6$..."
ssh_authorized_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."

iso_url      = "https://geo.mirror.pkgbuild.com/iso/..."
iso_checksum = "sha256:..."
```

**Important Notes:**
- The `ssh_username` and `ssh_password` must match the user credentials in the image
- The `ssh_password` is used by Packer during the build process
- Password hashes are embedded in the final VM image
- Never commit the `variables.auto.pkrvars.hcl` file (it's gitignored by default)
- Oracle/Rocky/Arch require separate root and user password hashes

### 3. Build the Image

#### Step 1: Initialize Packer Plugins

Download and install the required Packer plugins (run from the distribution directory):

```bash
# From ubuntu/, oracle/, rocky/, or arch/ directory
packer init .
```

This will download the VMware plugin specified in the configuration.

#### Step 2: Validate Configuration

Verify that your configuration is valid:

```bash
# From the distribution directory
packer validate -var-file=variables.auto.pkrvars.hcl .
```

If validation fails, check:
- All required variables are set in `variables.auto.pkrvars.hcl`
- Password hashes are properly formatted (enclosed in quotes)
- SSH key is a single line (no line breaks)
- File paths in `shell_scripts` exist
- ISO URL and checksum are correct

#### Step 3: Build the Image

Start the build process:

```bash
# From the distribution directory
packer build -var-file=variables.auto.pkrvars.hcl .
```

**Or specify the full path from the root:**
```bash
# Ubuntu Server
packer build -var-file=ubuntu/variables.auto.pkrvars.hcl ubuntu/

# Oracle Linux
packer build -var-file=oracle/variables.auto.pkrvars.hcl oracle/

# Rocky Linux
packer build -var-file=rocky/variables.auto.pkrvars.hcl rocky/

# Arch Linux
packer build -var-file=arch/variables.auto.pkrvars.hcl arch/
```

**Build Process:**
1. **Download ISO**: Packer downloads the Linux ISO (if not cached)
2. **Create VM**: Creates a new VMware virtual machine
3. **Boot from ISO**: Boots the VM and auto-installs the OS
   - Ubuntu: Uses cloud-init for automated installation
   - Oracle/Rocky: Uses Kickstart for automated installation
   - Arch: Uses custom installation script
4. **Wait for SSH**: Waits for the VM to become accessible via SSH
5. **Run Provisioners**: Executes shell scripts specified in `shell_scripts`
6. **Shutdown**: Powers off the VM
7. **Export**: Exports the VM as an OVA file

**Build Time:** Varies by distribution:
- **Ubuntu**: ~15-20 minutes
- **Oracle/Rocky**: ~20-30 minutes
- **Arch**: ~30-40 minutes (compiles packages)

Build time also depends on:
- Network speed (ISO download)
- Disk I/O performance
- Number of provisioning scripts

**Output Location:**
The built OVA file will be in:
```
# Ubuntu
output-ubuntu-server-cloudinit/
└── ubuntu-server.ova

# Oracle Linux
output-oracle-linux/
└── oracle-linux.ova

# Rocky Linux
output-rocky-linux/
└── rocky-linux.ova

# Arch Linux
output-arch-linux/
└── arch-linux.ova
```

#### Step 4: Verify the Build

Check that the OVA was created successfully:

```bash
# List the output directory contents
ls -lh output-*/
```

You can now import this OVA into VMware Workstation, ESXi, or VMware Cloud Director.

## Configuration Files

### Packer Configuration

Each distribution has its own directory structure:

**Ubuntu Server** (`ubuntu/`):
- **`ubuntu.pkr.hcl`**: Main Packer template
- **`variables.example.hcl`**: Example variables file
- **`config/user-data.pkrtpl.hcl`**: Cloud-init template
- **`config/meta-data`**: Cloud-init metadata

**Oracle Linux** (`oracle/`):
- **`oracle-linux.pkr.hcl`**: Main Packer template
- **`variables.example.hcl`**: Example variables file
- **`config/kickstart.cfg.pkrtpl.hcl`**: Kickstart template

**Rocky Linux** (`rocky/`):
- **`rocky-linux.pkr.hcl`**: Main Packer template
- **`variables.example.hcl`**: Example variables file
- **`config/kickstart.cfg.pkrtpl.hcl`**: Kickstart template

**Arch Linux** (`arch/`):
- **`arch-linux.pkr.hcl`**: Main Packer template
- **`variables.example.hcl`**: Example variables file
- **`config/install.sh.pkrtpl.hcl`**: Installation script template

**Common Files:**
- **`variables.auto.pkrvars.hcl`**: Your actual configuration (gitignored, never commit this)
- **`shell_scripts`**: Optional provisioning scripts

**Note:** All configuration templates use Packer's templating engine to render sensitive data (password hashes, SSH keys) at build time. This ensures credentials are never hardcoded in version control.

### Terraform Configuration (VCD Deployment)

If deploying to VMware Cloud Director:

1. Copy the example Terraform files:
   ```bash
   cp vcd.tf.example vcd.tf
   cp vcd.auto.tfvars.example vcd.auto.tfvars
   ```

2. Edit `vcd.auto.tfvars` with your VCD credentials:
   ```hcl
   vcd_user = "your-username"
   vcd_pass = "your-password"
   vcd_org  = "your-org-id"
   vcd_vdc  = "your-vdc-name"
   vcd_url  = "https://your-vcd-instance.com/api"
   ```

3. Deploy with Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Directory Structure

```
packer/
├── ubuntu/                        # Ubuntu Server configuration
│   ├── ubuntu.pkr.hcl            # Packer template
│   ├── variables.example.hcl      # Variables example
│   ├── README.md                  # Ubuntu-specific guide
│   └── config/
│       ├── user-data.pkrtpl.hcl  # Cloud-init template
│       ├── meta-data              # Cloud-init metadata
│       ├── init.sh                # Initial setup script
│       └── setup.sh               # Main provisioning script
│
├── oracle/                        # Oracle Linux configuration
│   ├── oracle-linux.pkr.hcl      # Packer template
│   ├── variables.example.hcl      # Variables example
│   ├── README.md                  # Oracle-specific guide
│   └── config/
│       └── kickstart.cfg.pkrtpl.hcl  # Kickstart template
│
├── rocky/                         # Rocky Linux configuration
│   ├── rocky-linux.pkr.hcl       # Packer template
│   ├── variables.example.hcl      # Variables example
│   ├── README.md                  # Rocky-specific guide
│   └── config/
│       └── kickstart.cfg.pkrtpl.hcl  # Kickstart template
│
├── arch/                          # Arch Linux configuration
│   ├── arch-linux.pkr.hcl        # Packer template
│   ├── variables.example.hcl      # Variables example
│   ├── README.md                  # Arch-specific guide
│   └── config/
│       └── install.sh.pkrtpl.hcl  # Installation script template
│
├── vcd.tf.example                 # Example Terraform VCD provider
├── vcd.auto.tfvars.example        # Example VCD credentials
├── output-*/                      # Build artifacts (gitignored)
│   └── *.ova                     # Generated OVA files
├── packer_cache/                  # Cached ISOs (gitignored)
├── .gitignore                     # Git ignore rules
├── README.md                      # This file (main documentation)
└── SECURITY.md                    # Security documentation
```

## Distribution-Specific Notes

### Ubuntu Server
- **Installer**: Cloud-init (autoinstall mode)
- **Packages**: Defined in `config/user-data.pkrtpl.hcl`
- **Password Hash**: Requires rounds parameter (`$6$rounds=4096$...`)
- **Boot Command**: Uses GRUB boot menu
- **Build Time**: ~15-20 minutes

### Oracle Linux
- **Installer**: Anaconda with Kickstart
- **Packages**: Defined in `config/kickstart.cfg.pkrtpl.hcl` (%packages section)
- **Password Hash**: Standard SHA-512
- **Boot Command**: Uses kernel boot parameters
- **Build Time**: ~20-30 minutes
- **ISO Downloads**: https://yum.oracle.com/oracle-linux-isos.html

### Rocky Linux
- **Installer**: Anaconda with Kickstart
- **Packages**: Defined in `config/kickstart.cfg.pkrtpl.hcl` (%packages section)
- **Password Hash**: Standard SHA-512
- **Boot Command**: Uses kernel boot parameters
- **Build Time**: ~20-30 minutes
- **ISO Downloads**: https://rockylinux.org/download

### Arch Linux
- **Installer**: Custom bash script
- **Packages**: Installed via pacman in `config/install.sh.pkrtpl.hcl`
- **Password Hash**: Standard SHA-512
- **Boot Command**: Interactive boot with password setup
- **Build Time**: ~30-40 minutes (longer due to package compilation)
- **ISO Downloads**: https://archlinux.org/download/
- **Note**: Arch requires a two-stage boot process (live ISO, then chroot install)

## Customization

### Modifying Provisioning Scripts

Each distribution has its own configuration files:

**Ubuntu:**
- Edit `config/user-data.pkrtpl.hcl` to modify packages and cloud-init settings
- Add post-install scripts via the `shell_scripts` variable

**Oracle/Rocky Linux:**
- Edit `config/kickstart.cfg.pkrtpl.hcl` to modify packages in the `%packages` section
- Add post-install commands in the `%post` section
- Add additional scripts via the `shell_scripts` variable

**Arch Linux:**
- Edit `config/install.sh.pkrtpl.hcl` to modify base installation
- Modify the `pacman -Sy --noconfirm` line to add/remove packages
- Add post-install scripts via the `shell_scripts` variable

### Changing OS Versions

To build a different version of a distribution:

1. Update the ISO URL and checksum in your `variables.auto.pkrvars.hcl`:
   ```hcl
   # Example for Ubuntu 24.04
   iso_url      = "https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso"
   iso_checksum = "sha256:<checksum-here>"

   # Example for Rocky Linux 8
   iso_url      = "https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.10-x86_64-minimal.iso"
   iso_checksum = "sha256:<checksum-here>"
   ```

2. Verify the boot command is compatible with the new version
3. Rebuild the image

### Adding Custom Scripts

Add additional provisioning scripts to the `shell_scripts` variable:

```hcl
shell_scripts = [
  "./config/setup.sh",
  "./config/custom-setup.sh"
]
```

## Security Best Practices

### Credential Management

- **Never commit credentials**: All `*.auto.tfvars`, `*.auto.pkrvars.hcl`, and `vcd.tf` files are gitignored
- **Use templating**: The configuration uses Packer's templating engine to keep sensitive data out of source control
- **Password hashes**: Always use SHA-512 hashed passwords with at least 4096 rounds
- **SSH keys**: Use ED25519 or RSA 4096-bit keys for authentication
- **Rotate credentials**: Regularly update passwords and regenerate VM images

### Build Security

- **Review scripts**: Always review provisioning scripts before running builds
- **Verify ISOs**: Check ISO checksums match official Ubuntu releases
- **Secure output**: Build artifacts in `output*/` are gitignored but should be secured
- **Clean up**: Remove old VMs and OVA files after deployment

### Template Variables

The configuration uses these sensitive variables (all marked as `sensitive = true`):
- `ssh_password`: Packer build password (temporary, only for build process)
- `password_hash`: User password hash (embedded in VM image)
- `ssh_authorized_key`: SSH public key (embedded in VM image)

These values are:
1. **Not** hardcoded in any tracked files
2. **Only** defined in your local `variables.auto.pkrvars.hcl` (gitignored)
3. **Rendered** at build time using Packer's `templatefile()` function
4. **Never** logged or displayed in Packer output (due to `sensitive` flag)

## Troubleshooting

### Template Rendering Errors

If you see errors like "Failed to render template" or "variable not set":

1. **Check all required variables are set** in `variables.auto.pkrvars.hcl`:
   ```bash
   # Required variables:
   # - password_hash
   # - ssh_authorized_key
   # - hostname (has default, but can be overridden)
   ```

2. **Verify password hash format**:
   - Must be enclosed in quotes: `password_hash = "$6$rounds=..."`
   - Must start with `$6$` for SHA-512
   - Should include `rounds=4096` or similar

3. **Check SSH key format**:
   - Must be a single line (no line breaks)
   - Should start with `ssh-rsa`, `ssh-ed25519`, etc.
   - Must be enclosed in quotes

### Build Fails with VNC Error

If you see VNC connection errors:

```bash
# Ensure the VNC port is not in use
netstat -an | grep 5971

# Change the VNC port in your variables file
vnc_port = 5972
```

### SSH Timeout During Build

If Packer times out waiting for SSH:

1. **Check credentials match**: `ssh_username` and `ssh_password` in variables must match the user created by cloud-init
2. **Verify cloud-init completed**: Check the VM console for cloud-init completion messages
3. **Check password hash**: Ensure the password hash in `password_hash` matches `ssh_password`
   ```bash
   # Verify your password hash:
   mkpasswd -m sha-512 -R 4096
   # Enter the same password as ssh_password
   ```
4. **Increase timeout**: Add to the source block in `ubuntu.pkr.hcl`:
   ```hcl
   ssh_timeout = "30m"
   ```
5. **Review VM console**: Look for boot errors or cloud-init failures

### ISO Download Fails

If ISO download fails or checksum doesn't match:

1. Verify the ISO URL is accessible
2. Update the checksum to match the current ISO
3. Use a different mirror if needed

### Cloud-Init User-Data Errors

If the VM boots but user account is not created:

1. **Check template syntax**: Validate `config/user-data.pkrtpl.hcl` has valid YAML after rendering
2. **Test template manually**:
   ```bash
   # This won't work directly, but you can check for syntax errors
   packer console ubuntu.pkr.hcl
   # Then type: local.user_data
   ```
3. **Check rendered output**: Look at the CD content during build (visible in Packer logs)

### Terraform VCD Connection Issues

If Terraform cannot connect to VCD:

1. Verify VCD URL is correct
2. Check credentials and organization ID
3. Ensure network connectivity to VCD
4. Check SSL certificate settings

## Additional Resources

- [Packer Documentation](https://www.packer.io/docs)
- [VMware Builder Documentation](https://www.packer.io/docs/builders/vmware)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Terraform VCD Provider](https://registry.terraform.io/providers/vmware/vcd/latest/docs)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file in the repository root for details.

Copyright (c) 2025 Serhii Nesterenko
