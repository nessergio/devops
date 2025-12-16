packer {
  required_plugins {
    vmware = {
      version = "~> 1.0.8"
      source = "github.com/hashicorp/vmware"
    }
  }
}

variable "vm_name" {
    default = "arch-linux"
}

variable "vm_cpu_cores" {
    type = number
    description = "The number of virtual CPUs cores per socket."
}

variable "vm_mem_size" {
    type = number
    description = "The size for the virtual memory in MB."
}

variable "vm_disk_size" {
    type = number
    description = "The size for the virtual disk in MB."
}

variable "vnc_port" {
    type = number
    default = 5974
    description = "The port for connecting via VNC."
}

variable "iso_url" {
    type = string
    description = "ISO file URL"
}

variable "iso_checksum" {
    type = string
    description = "ISO checksum"
}

variable "ssh_username" {
    type = string
    description = "The username to use to authenticate over SSH."
    default = "arch"
    sensitive = true
}

variable "ssh_password" {
    type = string
    description = "The plaintext password to use to authenticate over SSH."
    sensitive = true
}

variable "root_password_hash" {
    type = string
    description = "The root password hash (generated with mkpasswd -m sha-512)."
    sensitive = true
}

variable "user_password_hash" {
    type = string
    description = "The user password hash (generated with mkpasswd -m sha-512)."
    sensitive = true
}

variable "ssh_authorized_key" {
    type = string
    description = "The SSH public key to add to authorized_keys for the default user."
    sensitive = true
}

variable "hostname" {
    type = string
    description = "The hostname for the VM."
    default = "arch-linux"
}

variable "shell_scripts" {
    type = list(string)
    description = "A list of scripts."
    default = []
}

locals {
  install_script = templatefile("${path.root}/config/install.sh.pkrtpl.hcl", {
    hostname           = var.hostname
    username           = var.ssh_username
    root_password_hash = var.root_password_hash
    user_password_hash = var.user_password_hash
    ssh_authorized_key = var.ssh_authorized_key
    ssh_password       = var.ssh_password
  })
}

source "vmware-iso" "arch-linux" {
  format                 = "ova"
  iso_url                = var.iso_url
  iso_checksum           = var.iso_checksum
  ssh_username           = "root"
  ssh_password           = var.ssh_password
  headless               = "true"
  vnc_disable_password   = true
  vnc_port_min           = var.vnc_port
  vnc_port_max           = var.vnc_port
  vm_name                = var.vm_name
  vmdk_name              = var.vm_name
  guest_os_type          = "other5xlinux-64"
  ssh_timeout            = "30m"
  ssh_port               = "22"
  ssh_handshake_attempts = "100"
  shutdown_command       = "shutdown -P now"
  shutdown_timeout       = "15m"
  cpus                   = var.vm_cpu_cores
  memory                 = var.vm_mem_size
  disk_size              = var.vm_disk_size
  network_adapter_type   = "vmxnet3"
  boot_wait              = "20s"
  boot_command = [
    "<enter><wait60s>",
    "passwd<enter><wait>",
    "${var.ssh_password}<enter><wait>",
    "${var.ssh_password}<enter><wait>",
    "systemctl start sshd<enter><wait>"
  ]
}

build {
  sources = ["sources.vmware-iso.arch-linux"]

  # Upload and run installation script
  provisioner "file" {
    content = local.install_script
    destination = "/root/install.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x /root/install.sh",
      "/root/install.sh"
    ]
  }

  # Additional provisioning scripts
  provisioner "shell" {
    execute_command = "{{.Vars}} sudo -S -E bash '{{.Path}}'"
    environment_vars = [ "BUILD_USERNAME=${var.ssh_username}" ]
    scripts = var.shell_scripts
    expect_disconnect = true
    pause_before = "10s"
  }
}
