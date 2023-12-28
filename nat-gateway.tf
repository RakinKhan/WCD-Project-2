# NAT Gateway to install MySQL and open Port 3306
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_subnet_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on    = [aws_internet_gateway.public_IGW]
  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_route_table" "private_subnet_rt_nat" {
  vpc_id = aws_vpc.project_2_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_subnet_nat.id
  }
  tags = {
    Name = "NAT Route Table"
  }
}

resource "aws_route_table_association" "private_subnet_rt_association_nat" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_rt_nat.id

}