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
  vpc_id                  = aws_vpc.tf_vpc.id
  count                   = length(var.public_subnet_cidrs)
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
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
  nat_gateway_id         = aws_nat_gateway.nat_gateway[count.index].id
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


# -------------------------- instance & security group to test my default vpc --------------------------
resource "aws_security_group" "tf_sg" {
  description = "Custom Terraform security group"
  name        = "tf_sg"
  vpc_id      = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  description       = "Enable SSH"
  security_group_id = aws_security_group.tf_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.tf_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "allow_all_outbound"
  }
}

resource "aws_instance" "test_vpc_instance" {
  ami                    = "ami-091138d0f0d41ff90"
  key_name               = "ec2_key_pair"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.tf_sg.id]
  tags = {
    Name = "tf_ec2"
  }
}



# all the AWS resources required for a fully functional VPC:
#       - subnets (private and public)
#       - NAT gateway
#       - internet gateway
#       - route tables
#       - 2 AZs for enhanced availability
