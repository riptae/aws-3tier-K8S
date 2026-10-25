output "vpc_id" { value = aws_vpc.this.id }

output "node_subnet_ids" { value = aws_subnet.node[*].id }

output "db_subnet_ids" { value = aws_subnet.db[*].id }
