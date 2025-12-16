variable "ssh_key_pub" {
  type    = string
}

variable "ssh_key_private" {
  type    = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type    = string
}

variable "cloudflare_zone_id" {
  type    = string
}

variable "cidr_block_ipv4" {
  type    = string
  default = "172.16.0.0/16"
}

variable "registry" {
  type    = string  
  default = ""
}

variable "docker_pass" {
  type    = string  
  default = ""
}

locals {
  n_zones     = length(data.aws_availability_zones.available.names)
  name_prefix = "${var.tags["Environment"]}_${var.tags["Project"]}"
  dns_name    = var.tags["Project"]
}