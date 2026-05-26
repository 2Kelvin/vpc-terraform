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
