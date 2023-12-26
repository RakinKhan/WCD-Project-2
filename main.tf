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