resource "aws_instance" "web" {

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.web_sg.id
  ]

  user_data = templatefile("${path.module}/../../scripts/web.sh", {
    app_private_ip = var.app_private_ip
  })

  tags = {
    Name = "web-server"
  }

}

