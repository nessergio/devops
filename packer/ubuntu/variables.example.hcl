##################################################################################
# PACKER VARIABLES - Example Configuration
##################################################################################
# Copy this file to variables.auto.pkrvars.hcl and customize for your environment
# DO NOT commit the actual variables file with real credentials

# VM Configuration
vm_name                     = "ubuntu-server"
vm_cpu_cores                = 2
vm_mem_size                 = 2048
vm_disk_size                = 102400  # Size in MB
hostname                    = "ubuntu-server"

# SSH credentials for the build process (used by Packer to connect)
ssh_username                = "admin"
ssh_password                = "change-this-password"

# User configuration (embedded in the VM image)
# Generate password hash with: mkpasswd -m sha-512 -R 4096
# Example below is hash for "adminadmin" - CHANGE THIS!
password_hash               = "$6$rounds=4096$example$changeme"

# SSH public key to add to authorized_keys
# Replace with your own public key from ~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub
ssh_authorized_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@hostname"

# Ubuntu ISO configuration
iso_url                     = "https://mirror.easyname.at/ubuntu-releases/22.04.3/ubuntu-22.04.3-live-server-amd64.iso"
iso_checksum                = "sha256:a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"

# Shell scripts to run during provisioning
shell_scripts               = ["./config/setup.sh"]
