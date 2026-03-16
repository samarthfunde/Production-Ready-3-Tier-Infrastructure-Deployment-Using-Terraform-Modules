resource "aws_subnet" "public" {
  count = 2

  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]

 # Any EC2 instance launched in this subnet will automatically get a public IP.
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_app" {
  count = 2

  vpc_id = aws_vpc.main.id
  cidr_block = var.private_app_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "private-app-${count.index + 1}"
  }
}

resource "aws_subnet" "private_db" {
  count = 2

  vpc_id = aws_vpc.main.id
  cidr_block = var.private_db_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "private-db-${count.index + 1}"
  }
}