locals {
  cluster_name = data.terraform_remote_state.infrastructure.outputs.cluster_name
  region       = data.terraform_remote_state.infrastructure.outputs.aws_region
  vpc_id       = data.terraform_remote_state.infrastructure.outputs.vpc_id
  tags         = { Project = "aws-eks-3tier", Environment = "dev", ManagedBy = "terraform" }
}
