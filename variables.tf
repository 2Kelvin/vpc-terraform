variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.21.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets"
  type        = list(string)
  default     = ["10.0.12.0/24", "10.0.22.0/24"]
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}


variable "instance_type" {
  description = "EC2 type"
  type        = string
  default     = "t3.micro"
}

variable "instance_keypair" {
  description = "EC2 SSH key pair"
  type        = string
  default     = "ec2_key_pair"
}

variable "instance_ami" {
  description = "EC2 AMI"
  type        = string
  default     = "ami-091138d0f0d41ff90"
}
