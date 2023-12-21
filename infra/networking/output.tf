output "public_subnet_list" {
  value       = aws_subnet.public.*.id
  description = "list of public subnets"
}

output "natted_subnet_list" {
  value       = aws_subnet.natted.*.id
  description = "list of public subnets"
}