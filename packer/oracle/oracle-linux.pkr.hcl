packer {
  required_plugins {
    vmware = {
      version = "~> 1.0.8"
      source = "github.com/hashicorp/vmware"
    }
  }
}

variable "vm_name" {
    default = "oracle-linux"
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
    default = 5972
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
    default = "oracle"
    sensitive = true
}

variable "ssh_password" {
    type = string
    description = "The plaintext password to use to authenticate over SSH."
    sensitive = true
}

variable "root_password_hash" {
    type = string
    description = "The root password hash (generated with python -c 'import crypt; print(crypt.crypt(\"password\", crypt.mksalt(crypt.METHOD_SHA512)))')."
    sensitive = true
}

variable "user_password_hash" {
    type = string
    description = "The user password hash (generated with python -c 'import crypt; print(crypt.crypt(\"password\", crypt.mksalt(crypt.METHOD_SHA512)))')."
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
    default = "oracle-linux"
}

variable "shell_scripts" {
    type = list(string)
    description = "A list of scripts."
    default = []
}

locals {
  kickstart = templatefile("${path.root}/config/kickstart.cfg.pkrtpl.hcl", {
    hostname           = var.hostname
    username           = var.ssh_username
    root_password_hash = var.root_password_hash
    user_password_hash = var.user_password_hash
    ssh_authorized_key = var.ssh_authorized_key
  })
}

source "vmware-iso" "oracle-linux" {
  format                 = "ova"
  iso_url                = var.iso_url
  iso_checksum           = var.iso_checksum
  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  headless               = "true"
  vnc_disable_password   = true
  vnc_port_min           = var.vnc_port
  vnc_port_max           = var.vnc_port
  vm_name                = var.vm_name
  vmdk_name              = var.vm_name
  guest_os_type          = "oraclelinux-64"
  ssh_timeout            = "20m"
  ssh_port               = "22"
  ssh_handshake_attempts = "100"
  shutdown_command       = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  shutdown_timeout       = "15m"
  cpus                   = var.vm_cpu_cores
  memory                 = var.vm_mem_size
  disk_size              = var.vm_disk_size
  network_adapter_type   = "vmxnet3"
  boot_wait              = "5s"
  boot_command = [
    "<up><wait><tab><wait>",
    " inst.text inst.ks=cdrom:/ks.cfg",
    "<enter><wait>"
  ]
  cd_content = {
    "/ks.cfg" = local.kickstart
  }
  cd_label = "OEMDRV"
}

build {
  sources = ["sources.vmware-iso.oracle-linux"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    environment_vars = [ "BUILD_USERNAME=${var.ssh_username}" ]
    scripts = var.shell_scripts
    expect_disconnect = true
  }
}
