#!/bin/bash
set -e

# Arch Linux Installation Script

echo "==> Starting Arch Linux installation..."

# Update system clock
timedatectl set-ntp true

# Partition the disk
echo "==> Partitioning disk..."
parted -s /dev/sda mklabel msdos
parted -s /dev/sda mkpart primary ext4 1MiB 512MiB
parted -s /dev/sda set 1 boot on
parted -s /dev/sda mkpart primary ext4 512MiB 100%

# Format partitions
echo "==> Formatting partitions..."
mkfs.ext4 -F /dev/sda1
mkfs.ext4 -F /dev/sda2

# Mount partitions
echo "==> Mounting partitions..."
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install base system
echo "==> Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
echo "==> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot and configure system
echo "==> Configuring system..."
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "${hostname}" > /etc/hostname

# Configure hosts
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
HOSTS

# Set root password
echo "root:${root_password_hash}" | chpasswd -e

# Install essential packages
pacman -Sy --noconfirm openssh sudo vim wget curl net-tools python python-pip grub dhcpcd

# Install bootloader
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Create user
useradd -m -G wheel -p '${user_password_hash}' ${username}

# Configure sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Add SSH key
mkdir -p /home/${username}/.ssh
chmod 700 /home/${username}/.ssh
echo "${ssh_authorized_key}" > /home/${username}/.ssh/authorized_keys
chmod 600 /home/${username}/.ssh/authorized_keys
chown -R ${username}:${username} /home/${username}/.ssh

# Enable services
systemctl enable sshd
systemctl enable dhcpcd

EOF

# Unmount and reboot
echo "==> Installation complete. Rebooting..."
umount -R /mnt
sync

# Change SSH config to allow login with new user
# Note: After reboot, Packer will connect as the new user
systemctl restart sshd

# Reboot
reboot
