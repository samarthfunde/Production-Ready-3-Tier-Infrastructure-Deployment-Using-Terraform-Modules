output "web_public_ip" {
  value = module.web.public_ip
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}