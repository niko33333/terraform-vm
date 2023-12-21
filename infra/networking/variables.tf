variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "cidr_block" {
  type        = string
  description = "block address"
}

variable "env" {
  description = "type of the environment, e.g.: dev / prod"
}

variable "project_name" {
  description = "the name of the project"
}

variable "number_of_subnet" {
  description = "the number of private/natted/public subnet to create"
}

variable "number_of_nat" {
  description = "the number of nat gateway to create"
}