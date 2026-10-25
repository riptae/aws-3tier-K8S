locals {
  namespace          = "kube-system"
  service_account    = "aws-load-balancer-controller"
  oidc_host          = trimprefix(var.oidc_issuer_url, "https://")
  chart_version      = "1.14.0"
  controller_version = "v2.14.1"
}
