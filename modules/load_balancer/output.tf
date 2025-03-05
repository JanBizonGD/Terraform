output "load_balancer_url" {
  value = aws_lb.loadbalancer.dns_name
}
