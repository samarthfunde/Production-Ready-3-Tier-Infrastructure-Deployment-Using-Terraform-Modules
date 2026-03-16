resource "aws_db_subnet_group" "db_subnet" {

  name = "rds-subnet-group"

  subnet_ids = var.private_subnets

}