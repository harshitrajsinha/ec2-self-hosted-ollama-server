variable "region" {
  description = "AWS region to deploy resources in. If you change this, update var.azs to valid AZs for that region."
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "List of Availability Zones in which to create private subnets. One subnet is created per AZ. Defaults to a single AZ in us-east-1."
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Subnets are carved out of this range, one /24 per AZ."
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the SSM-managed private instance."
  type        = string
  default     = "t3.large"
}

variable "root_volume_gb" {
  description = "Root EBS volume size in GiB. ClickHouse data lives here."
  type        = number
  default     = 20
}

variable "enable_internet_access" {
  description = "Set true to create the public subnet, IGW, NAT gateway, route tables, and 443/80 egress rules on the EC2 SG so the private EC2 instance can reach the internet (e.g. for package updates). Default false keeps the instance fully isolated."
  type        = bool
  default     = false
}