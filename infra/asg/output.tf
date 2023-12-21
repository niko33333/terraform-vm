output "sg_ec2_asg" {
  value       = aws_security_group.ec2_security_group.id
  description = "the security group of the ec2 autoscaling groups"
}