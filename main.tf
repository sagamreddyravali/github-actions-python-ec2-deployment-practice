# --------------------------------
# VPC
# --------------------------------

resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# --------------------------------
# Internet Gateway
# --------------------------------

resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --------------------------------
# Public Subnet
# --------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Tier = "Public"
  }
}

# --------------------------------
# Private Subnet
# --------------------------------

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet"
    Tier = "Private"
  }
}

# --------------------------------
# Public Route Table
# --------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# --------------------------------
# Public Route Table Association
# --------------------------------

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --------------------------------
# NAT Elastic IP
# --------------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# --------------------------------
# NAT Gateway
# --------------------------------

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.app_igw,
    aws_route_table_association.public
  ]
}

# --------------------------------
# Private Route Table
# --------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app_vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# --------------------------------
# Private Route Table Association
# --------------------------------

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ==========================================
# SECURITY GROUP 1 - PUBLIC APPLICATION EC2
# ==========================================

resource "aws_security_group" "public_app_sg" {
  name        = "${var.project_name}-public-app-sg"
  description = "Security group for public Python application EC2"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "SSH from administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "Python Flask application"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.app_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-app-sg"
  }
}

# ==========================================
# SECURITY GROUP 2 - BASTION HOST
# ==========================================

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "SSH from administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# ==========================================
# SECURITY GROUP 3 - PRIVATE APPLICATION EC2
# ==========================================

resource "aws_security_group" "private_app_sg" {
  name        = "${var.project_name}-private-app-sg"
  description = "Security group for private Python application EC2"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description     = "SSH only from Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    description = "Flask application access from VPC"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-app-sg"
  }
}

# ==========================================
# IAM ROLE FOR PRIVATE EC2 SSM
# ==========================================

resource "aws_iam_role" "ssm_ec2_role" {
  name = "${var.project_name}-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ssm-ec2-role"
  }
}

# ==========================================
# ATTACH SSM MANAGED INSTANCE POLICY
# ==========================================

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role = aws_iam_role.ssm_ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==========================================
# S3 DOWNLOAD PERMISSION FOR PRIVATE EC2
# ==========================================

resource "aws_iam_role_policy" "ssm_s3_download" {
  name = "${var.project_name}-s3-download-policy"
  role = aws_iam_role.ssm_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "arn:aws:s3:::aws-python-app-github-actions-deployments/artifacts/*"
      }
    ]
  })
}

# ==========================================
# IAM INSTANCE PROFILE
# ==========================================

resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "${var.project_name}-ssm-ec2-profile"

  role = aws_iam_role.ssm_ec2_role.name
}

# ==========================================
# PUBLIC APPLICATION EC2
# ==========================================

resource "aws_instance" "public_app" {
  count = var.deployment_type == "public" ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_app_sg.id]
  key_name               = var.key_pair_name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y python3 python3-venv python3-pip git

    mkdir -p /opt/python-app
    chown ubuntu:ubuntu /opt/python-app
  EOF

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-public-ec2"
    Role = "Public Application Server"
  }

  depends_on = [
    aws_route_table_association.public
  ]
}

# ==========================================
# PRIVATE APPLICATION EC2 - SSM
# ==========================================

resource "aws_instance" "ssm_app" {
  count = var.deployment_type == "ssm" ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]
  key_name               = var.key_pair_name

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.ssm_ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y python3 python3-venv python3-pip git awscli

    mkdir -p /opt/python-app
    chown ubuntu:ubuntu /opt/python-app
  EOF

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-ssm-private-ec2"
    Role = "Private SSM Application Server"
  }

  depends_on = [
    aws_route_table_association.private,
    aws_iam_role_policy_attachment.ssm_policy,
    aws_iam_role_policy.ssm_s3_download
  ]
}

# ==========================================
# BASTION HOST EC2
# ==========================================

resource "aws_instance" "bastion" {
  count = var.deployment_type == "bastion" ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_pair_name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "Bastion Host"
  }

  depends_on = [
    aws_route_table_association.public
  ]
}

# ==========================================
# PRIVATE APPLICATION EC2 - BASTION
# ==========================================

resource "aws_instance" "bastion_private_app" {
  count = var.deployment_type == "bastion" ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_app_sg.id]
  key_name               = var.key_pair_name

  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y python3 python3-venv python3-pip git

    mkdir -p /opt/python-app
    chown ubuntu:ubuntu /opt/python-app
  EOF

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-bastion-private-ec2"
    Role = "Private Application Server"
  }

  depends_on = [
    aws_route_table_association.private
  ]
}
