provider "aws" {
  region = "eu-central-1"
}

# Create a vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}

# Create public subnets spread in multiple AZs
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.environment}-public-subnet-${count.index}"
    Role = "public"
  }
}

# # Create private subnets spread in multiple AZs
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.environment}-private-subnet-${count.index}"
    Role = "private"
  }
}

# Create an internet gateway for the vpc
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-internet-gw"
  }
}

# Only 1 eip will be created to reduce the cost during development
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# Will create only 1 nat gw to reduce the cost of eip
# Create a NAT gateway to give access to private subnet to the internet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.environment}-nat-gw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gw]
}

# Create a public route table 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Add this route to allow public access to the internet 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

# Create a private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.environment}-private-route-table"
  }
}

# Create association between public subnets and public route table
resource "aws_route_table_association" "public_subnet_associations" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create association between private subnets and private route table
resource "aws_route_table_association" "private_subnet_association" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
