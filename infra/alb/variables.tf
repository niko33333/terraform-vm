variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "env" {
  description = "type of the environment, e.g.: dev / prod"
}

variable "project_name" {
  description = "the name of the project"
}

variable "alb_subnet_list" {
  type        = list(string)
  description = "Subnet IDs for the alb"
}