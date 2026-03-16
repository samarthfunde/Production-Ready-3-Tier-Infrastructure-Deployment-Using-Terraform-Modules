resource "aws_instance" "app" {
  
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = var.private_subnet_id

  associate_public_ip_address = false
  key_name = var.key_name
  
  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

 user_data = templatefile("${path.module}/../../scripts/app.sh", {
  db_host = var.db_host
  db_user = var.db_user
  db_pass = var.db_pass
})

  tags = {
    Name = "app-server"
  }

}