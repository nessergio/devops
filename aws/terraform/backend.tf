terraform {
  backend "s3" {
    bucket = "demo.terraform.config"
    key    = "dev"
    region = "eu-central-1"
  }
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "demo"
  }
}

variable "region" {
  type    = string
  default = "eu-central-1"
}