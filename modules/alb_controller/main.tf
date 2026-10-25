# Own only this cluster's OIDC provider. Existing unrelated providers stay untouched.
resource "aws_iam_openid_connect_provider" "this" {
  url            = var.oidc_issuer_url
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

resource "aws_iam_policy" "this" {
  name   = "${var.cluster_name}-lbc"
  policy = file("${path.module}/iam_policy.json")
  tags   = var.tags
}

resource "aws_iam_role" "this" {
  name = "${var.cluster_name}-lbc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.this.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_host}:aud" = "sts.amazonaws.com"
        "${local.oidc_host}:sub" = "system:serviceaccount:${local.namespace}:${local.service_account}"
      } }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}


resource "helm_release" "this" {
  name       = "aws-load-balancer-controller"
  namespace  = local.namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = local.chart_version
  wait       = true
  timeout    = 600
  values = [yamlencode({
    clusterName  = var.cluster_name
    region       = var.region
    vpcId        = var.vpc_id
    replicaCount = 2
    image        = { tag = local.controller_version }
    serviceAccount = {
      create      = true
      name        = local.service_account
      annotations = { "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn }
    }
    # This sample uses Ingress, not Gateway API; no Gateway API CRDs are needed.
    controllerConfig = { featureGates = { ALBGatewayAPI = false, NLBGatewayAPI = false } }
  })]
  depends_on = [aws_iam_role_policy_attachment.this]
}
