module "vpc" {

  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr

  public_subnets      = var.public_subnets
  private_app_subnets = var.private_subnets
  private_db_subnets  = var.private_db_subnets

  azs = var.azs
}

module "web" {

  source = "./modules/web"

  vpc_id = module.vpc.vpc_id

  public_subnet_id = module.vpc.public_subnets[0]

  instance_type = var.instance_type
  ami_id        = var.ami_id

  app_private_ip = module.app.app_private_ip

  key_name = aws_key_pair.terraform_key.key_name

}

module "app" {

  source = "./modules/app"

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_app_subnets[0]

  instance_type = var.instance_type
  ami_id        = var.ami_id

  web_sg_id = module.web.web_sg_id

  db_host = module.rds.rds_endpoint
  db_user = var.db_user
  db_pass = var.db_password

  key_name = aws_key_pair.terraform_key.key_name

}

module "rds" {

  source = "./modules/rds"

  vpc_id = module.vpc.vpc_id

  private_subnets = module.vpc.private_db_subnets

  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password

  app_sg_id = module.app.app_sg_id
}