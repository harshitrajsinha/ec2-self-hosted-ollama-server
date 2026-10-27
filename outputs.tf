output "ec2_instance_id" {
  description = "ID of the SSM-managed private EC2 instance."
  value       = aws_instance.ssm_private.id
}

output "ec2_instance_private_ip" {
  description = "Private IP of the SSM-managed private EC2 instance."
  value       = aws_instance.ssm_private.private_ip
}

