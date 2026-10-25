resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = "10.20.${count.index + 1}.0/24"
  tags              = merge(var.tags, { Name = "${var.name}-public-${count.index + 1}", "kubernetes.io/role/elb" = "1" })
}

resource "aws_subnet" "node" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = "10.20.${count.index + 11}.0/24"
  tags              = merge(var.tags, { Name = "${var.name}-node-${count.index + 1}", "kubernetes.io/role/internal-elb" = "1" })
}

resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = "10.20.${count.index + 31}.0/24"
  tags              = merge(var.tags, { Name = "${var.name}-db-${count.index + 1}" })
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags   = var.tags
}

resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = var.tags
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = var.tags
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "node" {
  count  = 2
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = var.tags
}

resource "aws_route_table_association" "node" {
  count          = 2
  subnet_id      = aws_subnet.node[count.index].id
  route_table_id = aws_route_table.node[count.index].id
}

# DB 서브넷에는 인터넷 기본 경로를 만들지 않는다.
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

resource "aws_route_table_association" "db" {
  count          = 2
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
