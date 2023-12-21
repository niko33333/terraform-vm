output "alb_security_group_id" {
  value       = aws_security_group.alb_security_group.id
  description = "the security group id of the alb"
}

output "target_group_arn" {
  value       = aws_lb_target_group.alb_tg.arn
  description = "the target group in which register the ec2 instances"
}
