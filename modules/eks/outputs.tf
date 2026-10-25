output "cluster_name" { value = aws_eks_cluster.this.name }

output "node_security_group_id" { value = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id }
