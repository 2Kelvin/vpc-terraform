provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

# vpc
resource "aws_vpc" "tf_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "tf_vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "internet_gateway"
  }
}

# NAT EIPs
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  count  = length(var.private_subnet_cidrs)
  tags = {
    Name = "ElasticIP_${count.index + 1}"
  }
}

# subnets
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  count             = length(var.public_subnet_cidrs)
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  count             = length(var.private_subnet_cidrs)
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}

# NAT gateways
resource "aws_nat_gateway" "nat_gateway" {
  availability_mode = "zonal"
  count             = length(var.private_subnet_cidrs)
  allocation_id     = aws_eip.nat_eip[count.index].id
  subnet_id         = aws_subnet.public_subnet[count.index].id
  depends_on        = [aws_internet_gateway.igw]
  tags = {
    Name = "nat_gateway_${count.index + 1}"
  }
}

# route tables
resource "aws_route_table" "igw_route_table" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "igw_route_table"
  }
}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.tf_vpc.id
  count  = length(var.private_subnet_cidrs)
  tags = {
    Name = "nat_gateway_${count.index + 1}"
  }
}

# route table rules -> direct network traffic to internet gateway or NAT gateway
resource "aws_route" "igw_route_rules" {
  route_table_id         = aws_route_table.igw_route_table.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "nat_route_rules" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.nat_route_table[count.index].id
  gateway_id             = aws_nat_gateway.nat_gateway[count.index].id
  destination_cidr_block = "0.0.0.0/0"
}

# route table association -> linking route tables and their rules to respective subnets
# both public subnets in each AZs point to the one internet gateway
resource "aws_route_table_association" "public_igw_route_assoc" {
  count          = length(var.public_subnet_cidrs)
  route_table_id = aws_route_table.igw_route_table.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

# each private subnet points to its own NAT gateway in each AZ
resource "aws_route_table_association" "private_nat_route_assoc" {
  count          = length(var.private_subnet_cidrs)
  route_table_id = aws_route_table.nat_route_table[count.index].id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}


# Todo
#       - use count/for-each for repetitive resources
#       - add variables file


# all the AWS resources required for a fully functional VPC:
#       - subnets (private and public)
#       - NAT gateway
#       - internet gateway
#       - route tables
