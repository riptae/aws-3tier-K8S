variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
  validation {
    condition     = var.aws_region == "ap-northeast-2"
  }
}
variable "name" {
  type    = string
  default = "eks-3tier-dev"
}
variable "admin_principal_arn" {
  type        = string
  default     = "arn:aws:iam::569853361595:user/aws-cli-final"
  description = "kubectl -> K8S API"
}
variable "admin_cidrs" {
  type        = list(string)
  default     = ["XXX.XXX.XXX.XXX/32"]
  description = "EKS API 접근을 허용할 관리자 공인 IP/32"
}
variable "db_password" {
  type      = string
  sensitive = true
}
