output "cluster_name" { value = module.eks.cluster_name }
output "vpc_id" { value = module.network.vpc_id }
output "web_repository_url" { value = module.ecr.web_repository_url }
output "app_repository_url" { value = module.ecr.app_repository_url }
output "db_address" { value = module.database.address }
output "aws_region" { value = var.aws_region }
