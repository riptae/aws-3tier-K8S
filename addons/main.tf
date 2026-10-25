# Separate state: infrastructure must already exist before applying addons.
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config  = { path = var.infrastructure_state_path }
}

data "aws_eks_cluster" "this" { 
  name = local.cluster_name 
}

module "alb_controller" {
  source          = "../modules/alb_controller"
  cluster_name    = local.cluster_name
  region          = local.region
  vpc_id          = local.vpc_id
  oidc_issuer_url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags            = local.tags
}
