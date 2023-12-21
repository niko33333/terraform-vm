##### COMMON #####
variable "region" {
  description = "region in which environment will be created"
}

variable "env" {
  description = "type of the environment, e.g.: dev / prod"
}

variable "project_name" {
  description = "the name of the project"
}

##### NETWORKING #####
variable "vpc_cidr" {
  description = "VPC CIDR"
}
