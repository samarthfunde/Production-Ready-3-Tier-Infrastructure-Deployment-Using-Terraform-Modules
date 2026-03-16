variable "vpc_id" {}

variable "private_subnets" {
  type = list(string)
}

variable "db_name" {}

variable "db_user" {}

variable "db_password" {}

variable "app_sg_id" {}