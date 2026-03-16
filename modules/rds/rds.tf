resource "aws_db_instance" "mysql" {

  allocated_storage = 20

  engine = "mysql"

  instance_class = "db.t3.micro"

  db_name = var.db_name

  username = var.db_user

  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.db_subnet.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  skip_final_snapshot = true
}