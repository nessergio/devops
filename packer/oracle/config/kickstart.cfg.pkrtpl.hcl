# Oracle Linux Kickstart Configuration
# System authorization information
auth --enableshadow --passalgo=sha512

# Use text mode install
text

# Run the Setup Agent on first boot
firstboot --disable

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
network --bootproto=dhcp --device=eth0 --onboot=yes --ipv6=auto --activate
network --hostname=${hostname}

# Root password (hashed)
rootpw --iscrypted ${root_password_hash}

# System timezone
timezone UTC --utc

# System bootloader configuration
bootloader --location=mbr --boot-drive=sda

# Partition clearing information
clearpart --all --initlabel

# Disk partitioning information
autopart --type=lvm

# Accept EULA
eula --agreed

# Reboot after installation
reboot

# Package selection
%packages --ignoremissing --excludedocs
@core
@base
openssh-server
openssh-clients
sudo
wget
curl
vim
net-tools
bind-utils
python3
python3-pip
-firewalld
-postfix
%end

# Post-installation script
%post --log=/root/ks-post.log

# Create user
useradd -m -G wheel -p '${user_password_hash}' ${username}

# Add SSH key
mkdir -p /home/${username}/.ssh
chmod 700 /home/${username}/.ssh
echo "${ssh_authorized_key}" > /home/${username}/.ssh/authorized_keys
chmod 600 /home/${username}/.ssh/authorized_keys
chown -R ${username}:${username} /home/${username}/.ssh

# Configure sudo for user
echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username}
chmod 440 /etc/sudoers.d/${username}

# Enable SSH
systemctl enable sshd

# Update system (optional, can be slow)
# yum -y update

# Clean up
yum clean all

%end
