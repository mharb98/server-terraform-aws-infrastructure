output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  description = "The public subnet IDs in VPC"
  value       = module.vpc.vpc_public_subnets
}

output "vpc_public_subnets" {
  description = "The private subnet IDS in VPC"
  value       = module.vpc.vpc_private_subnets
}
