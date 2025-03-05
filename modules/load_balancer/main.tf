provider "aws" {
  shared_config_files      = ["${var.cred_location}/config"]
  shared_credentials_files = ["${var.cred_location}/credentials"]
  region = var.region
}

resource "aws_lb" "loadbalancer" {
  name               = var.name
  internal           = false # no internet gateway error if false
  load_balancer_type = "application"
  security_groups   = var.security_groups
  subnets            = var.subnets 
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.virtual_network 
  health_check {
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "asg_attachment" {
  depends_on = [ var.instances ]
  count = length(var.instances)
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = var.instances[count.index]
  port             = 80
}
