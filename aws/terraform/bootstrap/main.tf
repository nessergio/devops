terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 0.13"
}

# Create AWS Provider and set the Region
provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "config" {
  bucket = "${var.project}.terraform.config"
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "local_file" "backend" {
  content         = templatefile("backend.tftpl", {
    region      = var.region
    bucket_name = aws_s3_bucket.config.bucket
    bucket_key  = "${var.environment}"
    environment = var.environment
    project     = var.project
  })
  filename        = "${path.module}/../backend.tf"
  file_permission = "0664"
}
