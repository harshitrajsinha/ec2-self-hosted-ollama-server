# ---------------------------------------------------------------------------
# The two groups
#   - EC2 SG egress      443 -> VPC endpoints SG
#   - VPC endpoints SG ingress 443 <- EC2 SG
# ---------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "ssm-vpce-sg"
  description = "Ingress 443 from the EC2 SG; egress all to internet."
  vpc_id      = aws_vpc.this.id

  # All outbound traffic to the internet.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "ssm-vpce-sg"
    ManagedBy = "terraform"
  }
}

# 2) Security group attached to the private EC2 instance (SSM-managed, no
#    inbound traffic).
resource "aws_security_group" "ec2" {
  name        = "ssm-ec2-sg"
  description = "No inbound. Outbound only 443 to the VPC endpoints SG."
  vpc_id      = aws_vpc.this.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpc_endpoints.id]
  }

  # Outbound 443 and 80 to the internet (0.0.0.0/0) - only present while
  # var.enable_internet_access is true.
  dynamic "egress" {
    for_each = var.enable_internet_access ? [443, 80] : []
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name      = "ssm-ec2-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_https_from_ec2" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS from the private EC2 instance SG."
}
