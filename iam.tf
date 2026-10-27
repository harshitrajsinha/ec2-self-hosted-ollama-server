# ---------------------------------------------------------------------------
# IAM for SSM:
#   1. EC2 instance role - AWS service = EC2, use case = "EC2 Role for AWS
#      Systems Manager". 
#   2. IAM user with full SSM access. No access keys are
#      created here - create them yourself and add them to a local AWS profile for ssm agent command run.
# ---------------------------------------------------------------------------

# ---------- 1) EC2 instance role for SSM --------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name               = "ec2-ssm-role"
  description        = "EC2 instance role for AWS Systems Manager (SSM managed instance)."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2-ssm-instance-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ---------- 2) IAM user for local SSM / Session Manager access ----------------

resource "aws_iam_user" "ssm_operator" {
  name = "ssm-operator"
  path = "/"

  tags = {
    Purpose   = "Session Manager access to private instances"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_user_policy_attachment" "ssm_operator_full_access" {
  user       = aws_iam_user.ssm_operator.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}
