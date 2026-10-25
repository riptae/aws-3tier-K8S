module "network" {
  source = "../modules/network"
  name   = var.name
  tags   = local.tags
}

module "security" {
  source                 = "../modules/security"
  name                   = var.name
  vpc_id                 = module.network.vpc_id
  node_security_group_id = module.eks.node_security_group_id
  tags                   = local.tags
}

module "eks" {
  source              = "../modules/eks"
  name                = var.name
  subnet_ids          = module.network.node_subnet_ids
  admin_cidrs         = var.admin_cidrs
  admin_principal_arn = var.admin_principal_arn
  tags                = local.tags
  depends_on          = [module.network]
}


module "database" {
  source            = "../modules/database"
  name              = var.name
  subnet_ids        = module.network.db_subnet_ids
  security_group_id = module.security.db_security_group_id
  password          = var.db_password
  tags              = local.tags
}

module "ecr" {
  source = "../modules/ecr"
  name   = var.name
  tags   = local.tags
}
