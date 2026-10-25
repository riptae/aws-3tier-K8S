# 기본 VPC CNI 구성의 Pod는 노드 SG를 사용한다. App 전용 격리는 후속 확장.
resource "aws_security_group" "db" {
  name   = "${var.name}-db"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }
  tags = var.tags
}
