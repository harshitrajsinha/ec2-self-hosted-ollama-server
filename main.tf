# VPC with DNS resolution and DNS hostnames enabled.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "ssm-private-vpc"
    ManagedBy = "terraform"
  }
}

# Private subnets: one per AZ listed in var.azs.
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name      = "ssm-private-${var.azs[count.index]}"
    ManagedBy = "terraform"
  }
}
