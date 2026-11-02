# Python Flask Application Deployment Using GitHub Actions

## Project Overview

This project demonstrates deploying a Python Flask application to AWS EC2 using GitHub Actions and Terraform.

It covers three deployment scenarios:

1. Public EC2 deployment using SSH.
2. Private EC2 deployment using AWS Systems Manager (SSM).
3. Private EC2 deployment through a Bastion host.

## Technologies Used

- AWS EC2
- AWS VPC
- AWS IAM
- AWS Systems Manager
- Terraform
- Python
- Flask
- Gunicorn
- Linux
- Git and GitHub
- GitHub Actions

## Application

The Flask application runs on port 5000.

### Endpoints

- `/` - Application welcome message.
- `/health` - Application health check.

## Infrastructure

Terraform provisions:

- VPC
- Public and private subnets
- Internet Gateway
- NAT Gateway (optional)
- Route tables
- Security groups
- EC2 instances
- IAM role and instance profile for SSM

## Deployment Scenarios

### 1. Public EC2

GitHub Actions deploys the application to a public EC2 instance using SSH.

### 2. Private EC2 using SSM

GitHub Actions authenticates to AWS using OIDC and deploys to a private EC2 instance using Systems Manager.

### 3. Private EC2 using Bastion

The application runs on a private EC2 instance, which is accessed through a Bastion host.

## Repository Structure

See the repository folders and files for Terraform infrastructure, application code, deployment scripts, and GitHub Actions workflows.

## Important

- Do not commit AWS credentials, private keys, Terraform state files, or `terraform.tfvars`.
- Use GitHub Secrets and AWS OIDC for secure authentication.
- NAT Gateway and EC2 resources can incur AWS charges.