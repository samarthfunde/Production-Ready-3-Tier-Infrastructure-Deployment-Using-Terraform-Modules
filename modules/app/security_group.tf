resource "aws_security_group" "app_sg" {

  name = "app-sg"
  vpc_id = var.vpc_id

  ingress {

    from_port = 5000
    to_port = 5000
    protocol = "tcp"

    security_groups = [var.web_sg_id]

  }

  ingress {

    from_port = 22
    to_port = 22
    protocol = "tcp"

    security_groups = [var.web_sg_id]

  }

  egress {

    from_port = 0
    to_port = 0
    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}