region = "ap-south-1"

vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

private_db_subnets = [
  "10.0.5.0/24",
  "10.0.6.0/24"
]

azs = [
  "ap-south-1a",
  "ap-south-1b"
]

instance_type = "t2.micro"

ami_id = "ami-0f559c3642608c138"

db_name = "appdb"

db_user = "admin"

db_password = "Password123!"