variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "env" {
  description = "type of the environment, e.g.: dev / prod"
}

variable "region" {
  description = "The aws region"
}

variable "project_name" {
  description = "the name of the project"
}

variable "security_group_alb_id" {
  description = "the id of the alb security group to access the ec2"
}

variable "ec2_natted_subnet_list" {
  type        = list(string)
  description = "Subnet IDs for the ec2"
}

variable "target_group_arn" {
  description = "the arn of the target group"
}

variable "volume_size" {
  description = "the size of the volume to launch with lt"
}

variable "instance_type" {
  description = "the instance type to launch with lt"
}

variable "image_id" {
  description = "the image id to launch with lt"
}

variable "docker_image" {
  description = "the name of docker image to run in the ec2"
}
