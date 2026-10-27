# ---------------------------------------------------------------------------
# VPC interface endpoints for AWS Systems Manager (SSM).
#
# Three interface endpoints are created so a private EC2 instance with no
# internet access can still be managed by SSM:
#   - ssm          : SSM control plane (StartSession, commands, etc.)
#   - ec2messages  : traffic between the SSM Agent and EC2 (e.g. RunCommand)
#   - ssmmessages  : Session Manager / port-forwarding data channel
# ---------------------------------------------------------------------------

locals {
  ssm_interface_services = toset([
    "ssm",
    "ec2messages",
    "ssmmessages",
  ])
}

resource "aws_vpc_endpoint" "ssm_interface" {
  for_each = local.ssm_interface_services

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name      = "ssm-${each.value}-endpoint"
    ManagedBy = "terraform"
  }
}
