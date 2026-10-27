# ---------------------------------------------------------------------------
# Internet access for the private EC2 instance to 
# download and install packages/tools (optional, disabled by default).
#
# This entire file is gated by var.enable_internet_access (default false).
# When false, none of these resources exist and the instance stays fully
# isolated (egress only 443 to the SSM VPC endpoints, no internet route).
# When true, it creates:
#   - a public subnet (same AZ as the instance's subnet, one AZ only),
#   - an internet gateway,
#   - a public route table (0.0.0.0/0 -> IGW) for the public subnet,
#   - an elastic IP + NAT gateway in the public subnet,
#   - a private route table (0.0.0.0/0 -> NAT) attached to the instance's
#     private subnet (aws_subnet.private[0]).
#
# Toggle:
#   terraform apply -var enable_internet_access=true    # enable
#   terraform apply -var enable_internet_access=false   # disable (destroys all of the above)
# ---------------------------------------------------------------------------

# Public subnet - same AZ as the instance's subnet (var.azs[0]), one AZ only.
# CIDR is the next /24 after the private subnets to avoid overlap.
resource "aws_subnet" "public" {
  count                   = var.enable_internet_access ? 1 : 0
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, length(var.azs))
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name      = "internet-public-${var.azs[0]}"
    ManagedBy = "terraform"
  }
}

# Internet gateway attached to the VPC.
resource "aws_internet_gateway" "this" {
  count  = var.enable_internet_access ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "internet-igw"
    ManagedBy = "terraform"
  }
}

# Public route table: default route -> IGW, associated with the public subnet.
resource "aws_route_table" "public" {
  count  = var.enable_internet_access ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name      = "internet-public-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.enable_internet_access ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

# Elastic IP for the NAT gateway.
resource "aws_eip" "nat" {
  count  = var.enable_internet_access ? 1 : 0
  domain = "vpc"

  tags = {
    Name      = "internet-nat-eip"
    ManagedBy = "terraform"
  }
}

# NAT gateway in the public subnet (same AZ as the instance).
resource "aws_nat_gateway" "this" {
  count         = var.enable_internet_access ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name      = "internet-nat"
    ManagedBy = "terraform"
  }
}

# Private route table: default route -> NAT, associated with the instance's
# private subnet (aws_subnet.private[0]). When this is disabled, the subnet
# falls back to the VPC default route table (no internet route).
resource "aws_route_table" "private_internet" {
  count  = var.enable_internet_access ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = {
    Name      = "internet-private-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "private_internet" {
  count          = var.enable_internet_access ? 1 : 0
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private_internet[0].id
}
