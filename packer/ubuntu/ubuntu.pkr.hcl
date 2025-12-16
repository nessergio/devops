packer {
  required_plugins {
    vmware = {
      version = "~> 1.0.8"
      source = "github.com/hashicorp/vmware"
    }
  }
}

variable "vm_name" {
    default = "ubuntu-server"
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
    default = 5971
    description = "The port for connectiong via VNC." 
}

variable "iso_url" {
    type = string
    description = "iso file URL"
}

variable "iso_checksum" {
    type = string
    description = "iso checksum"
}

variable "ssh_username" {
    type = string
    description = "The username to use to authenticate over SSH."
    default = "ubuntu"
    sensitive = true
}

variable "ssh_password" {
    type = string
    description = "The plaintext password to use to authenticate over SSH."
    default = "adminadmin"
    sensitive = true
}

variable "password_hash" {
    type = string
    description = "The password hash for the default user (generated with mkpasswd)."
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
    default = "ubuntu-server"
}

variable "shell_scripts" {
    type = list(string)
    description = "A list of scripts."
    default = []
}

locals {
  user_data = templatefile("${path.root}/config/user-data.pkrtpl.hcl", {
    hostname           = var.hostname
    username           = var.ssh_username
    password_hash      = var.password_hash
    ssh_authorized_key = var.ssh_authorized_key
  })
}

source "vmware-iso" "ubuntu-server-cloudinit" {
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
  guest_os_type          = "ubuntu-64"
  ssh_timeout            = "20m"
  ssh_port               = "22"
  ssh_handshake_attempts = "100"
  shutdown_command       = "sudo systemctl poweroff"
  shutdown_timeout       = "15m"
  cpus                   = var.vm_cpu_cores
  memory                 = var.vm_mem_size
  disk_size              = var.vm_disk_size
  network_adapter_type   = "vmxnet3"
  boot_wait              = "5s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz autoinstall ds=nocloud ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  cd_content = {
    "/meta-data" = file("${path.root}/config/meta-data")
    "/user-data" = local.user_data
  }
  cd_label = "cidata"
}

build {
  sources = ["sources.vmware-iso.ubuntu-server-cloudinit"]
  provisioner "shell" {     
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"     
    environment_vars = [ "BUILD_USERNAME=${var.ssh_username}" ]     
    scripts = var.shell_scripts     
    expect_disconnect = true   
  }
} 
