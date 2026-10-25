
resource "aws_iam_role" "cluster" {
  name               = "${var.name}-cluster"
  assume_role_policy = jsonencode({ 
    Version = "2012-10-17", 
    Statement = [{ 
      Effect = "Allow", 
      Principal = { Service = "eks.amazonaws.com" }, 
      Action = "sts:AssumeRole" }] 
    })
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = "1.35"
  role_arn = aws_iam_role.cluster.arn // EKS서비스가 AWS리소스 관리할 때 사용할 Role
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.admin_cidrs
  }
  tags       = var.tags
  depends_on = [aws_iam_role_policy_attachment.cluster]
}

// 권한 for Helm, Controller설치
resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}

// 워커 노드 권한
resource "aws_iam_role" "node" {
  name               = "${var.name}-node"
  assume_role_policy = jsonencode({ 
    Version = "2012-10-17", 
    Statement = [{ 
      Effect = "Allow", 
      Principal = { 
        Service = "ec2.amazonaws.com" 
      } , Action = "sts:AssumeRole" 
    }] 
  })
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each   = toset(["AmazonEKSWorkerNodePolicy", 
                    "AmazonEC2ContainerRegistryReadOnly", 
                    "AmazonEKS_CNI_Policy"])
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# AZ별 1대씩 고정 배치하는 최소 예제. 실제 Pod는 topology spread로 분산.
resource "aws_eks_node_group" "this" {
  count           = 2
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-${count.index + 1}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [var.subnet_ids[count.index]]
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_types  = ["t3.medium"]
  disk_size       = 20
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }
  update_config { max_unavailable = 1 }
  tags       = var.tags
  depends_on = [aws_iam_role_policy_attachment.node]
}
