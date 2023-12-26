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

# 1v) Public Route Table 
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
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        security_groups = [aws_security_group.public_security_group]
  }
}
# 1v-ii Public Subnet Security Group
resource "aws_security_group" "public_security_group" {
  ingress {
    from_port = 22
    to_port = 22
    protocol = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 80      
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}