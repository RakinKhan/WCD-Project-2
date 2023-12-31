terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }

  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.credentials.access_key
  secret_key = var.credentials.secret_key

}

# 1i) Create VPC
resource "aws_vpc" "project_2_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Project 2 VPC"
  }
}

# 1ii) Internet Gateway
resource "aws_internet_gateway" "public_IGW" {
  vpc_id = aws_vpc.project_2_vpc.id

  tags = {
    Name = "Public Internet Gateway"
  }
}

# 1iii) Public & Private Subnets
resource "aws_subnet" "public_subnet" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.project_2_vpc.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.project_2_vpc.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "Private Subnet"
  }
}

# 1v) Public Subnet RT Association
resource "aws_route_table_association" "public_rt_association_igw" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# 1iv) Public Route Table 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.project_2_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_IGW.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# 1v-i) Private Subnet Security Group
resource "aws_security_group" "private_security_group" {
  vpc_id = aws_vpc.project_2_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Allows traffic from Public Subnet to Private Subnet
    security_groups = [aws_security_group.public_security_group.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Private Subnet Security Group"
  }
}
# 1v-ii Public Subnet Security Group
resource "aws_security_group" "public_security_group" {
  vpc_id = aws_vpc.project_2_vpc.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public Subnet Security Group"
  }
}

# Security Key-Pair
resource "aws_key_pair" "WCD_project_2_key" {
  # If you have a public .pem key already, change key name below to match the .pem key.
  key_name = "WCD_project_2_key"
  # Make sure that the path to the public key matches its exact location. 
  public_key = file("~/.ssh/id_rsa.pub")
}

# 2i) EC2 Instance For Database Server
resource "aws_instance" "database_server" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_security_group.private_security_group.id]
  key_name                    = aws_key_pair.WCD_project_2_key.key_name
  associate_public_ip_address = false
  # Updates and Upgrades APT packages, installs and starts MySQL server. Opens port 3306 for database connection.
  user_data                   = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install mysql-server -y
    sudo systemctl start mysql
    sudo systemctl status mysql
    sudo ufw allow 3306/tcp
  EOF

  tags = {
    Name = "MySQL Server"
  }
  # Database Server in Private Subnet will be created only after the creation and association of the NAT Gateway.
  # This is because the Instance will fail to install the packages without establishing internet connection first. 
  depends_on = [aws_route_table_association.private_subnet_rt_association_nat]
}

# 2ii) EC2 instance for Fastapi Server
resource "aws_instance" "public_api_server" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_security_group.id]
  key_name                    = aws_key_pair.WCD_project_2_key.key_name
  associate_public_ip_address = true
  # Updates and Upgrades APT packages, installs Python, Pip, Fastapi, and Uvicorn packages.
  user_data                   = <<-EOF
    #! /bin/bash
    sudo apt update -y
    sudo apt upgrade -y 
    sudo apt install python3 -y
    sudo apt install python3-pip -y
    pip3 install fastapi
    pip3 install uvicorn
    EOF
  tags = {
    Name = "Fastapi Server"
  }
}

