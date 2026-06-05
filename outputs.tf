output "frontend_public_ip" {
  value       = module.frontend_ec2.public_ip
  description = "Frontend EC2 Public IP"
}

output "backend_public_ip" {
  value       = module.backend_ec2.public_ip
  description = "Backend EC2 Public IP"
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "RDS MySQL Endpoint"
}

output "s3_bucket_name" {
  value       = module.s3.bucket_name
  description = "S3 Bucket Name"
}

output "frontend_security_group_id" {
  value = module.security_groups.frontend_sg_id
}

output "backend_security_group_id" {
  value = module.security_groups.backend_sg_id
}

output "rds_security_group_id" {
  value = module.security_groups.rds_sg_id
}
