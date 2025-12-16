##################################################################################
# PACKER VARIABLES - Oracle Linux Example Configuration
##################################################################################
# Copy this file to variables.auto.pkrvars.hcl and customize for your environment
# DO NOT commit the actual variables file with real credentials

# VM Configuration
vm_name                     = "oracle-linux"
vm_cpu_cores                = 2
vm_mem_size                 = 2048
vm_disk_size                = 102400  # Size in MB
hostname                    = "oracle-linux"

# SSH credentials for the build process (used by Packer to connect)
ssh_username                = "oracle"
ssh_password                = "change-this-password"

# User and Root configuration (embedded in the VM image)
# Generate password hash with:
# python3 -c 'import crypt; print(crypt.crypt("your-password", crypt.mksalt(crypt.METHOD_SHA512)))'
root_password_hash          = "$6$example$changeme"
user_password_hash          = "$6$example$changeme"

# SSH public key to add to authorized_keys
# Replace with your own public key from ~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub
ssh_authorized_key          = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@hostname"

# Oracle Linux ISO configuration
# Download from: https://yum.oracle.com/oracle-linux-isos.html
iso_url                     = "https://yum.oracle.com/ISOS/OracleLinux/OL9/u5/x86_64/OracleLinux-R9-U5-x86_64-dvd.iso"
iso_checksum                = "sha256:CHANGE-THIS-TO-ACTUAL-CHECKSUM"

# Shell scripts to run during provisioning
shell_scripts               = []
