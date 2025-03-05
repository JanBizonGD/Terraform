output "virtual_network_id" {
    value = aws_vpc.this.id
}

output "virtual_subnet_ids" {
  value = [aws_subnet.this.id, aws_subnet.this2.id]
}
