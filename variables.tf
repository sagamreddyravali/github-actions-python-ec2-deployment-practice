variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "python-github-actions"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}

variable "deployment_type" {
  description = "Deployment scenario: public, ssm, or bastion"
  type        = string

  validation {
    condition     = contains(["public", "ssm", "bastion"], var.deployment_type)
    error_message = "Choose public, ssm, or bastion."
  }
}

# VPC configuration

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet IPv4 CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet IPv4 CIDR"
  type        = string
  default     = "10.20.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for subnet resources"
  type        = string
  default     = "us-east-1a"
}

# EC2 configuration

variable "ami_id" {
  description = "Ubuntu Server 24.04 LTS AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name (not required for SSM deployment)"
  type        = string
  default     = ""

  validation {
    condition     = var.deployment_type == "ssm" || trimspace(var.key_pair_name) != ""
    error_message = "An existing EC2 key pair name is required for public and bastion deployments."
  }
}

variable "root_volume_size" {
  description = "EC2 root EBS volume size in GiB"
  type        = number
  default     = 8
}

# Network access configuration

variable "ssh_ingress_cidr" {
  description = "Administrator public IP CIDR for SSH"
  type        = string
}

variable "app_ingress_cidr" {
  description = "Allowed CIDR for application access on port 5000"
  type        = string
}

# NAT configuration

variable "enable_nat_gateway" {
  description = "Create NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}
