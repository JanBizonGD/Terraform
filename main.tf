terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  shared_config_files      = ["/root/.aws/config"]
  shared_credentials_files = ["/root/.aws/credentials"]
  region = var.aws_region
}

module "lb_network_setup" {
  source = "./modules/lb_network_setup"
}
module "instance_group" {
  source = "./modules/instance_group"
  security_groups = [aws_security_group.lb_sg.id]
  vpc_zone_identifiers = [module.lb_network_setup.virtual_subnet_ids[0]]
  availability_zone = "${var.aws_region}a"
}


data "aws_instances" "instances_in_subnet" {
  filter {
    name   = "subnet-id"
    values = [module.lb_network_setup.virtual_subnet_ids[0]]
  }
  depends_on = [module.instance_group.autoscale_group]
}

# output "instance_ids" {
#   value = [for instance in data.aws_instances.instances_in_subnet : instance.private_dns]
# }

resource "aws_lb" "loadbalancer" {
  name               = "app-lb"
  internal           = false # no internet gateway error if false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.lb_sg.id]
  subnets            = module.lb_network_setup.virtual_subnet_ids #[aws_subnet.instance_subnet1.id, aws_subnet.instance_subnet2.id]
}

resource "aws_lb_target_group" "app_target_group" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.lb_network_setup.virtual_network_id #aws_vpc.autoscale_vpc.id
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
  depends_on = [ data.aws_instances.instances_in_subnet ]
  count = length(data.aws_instances.instances_in_subnet.ids)
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = data.aws_instances.instances_in_subnet.ids[count.index]
  port             = 80
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Allow HTTP traffic"
  vpc_id = module.lb_network_setup.virtual_network_id #aws_vpc.autoscale_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "lb_sq_ingress" {
    security_group_id = aws_security_group.lb_sg.id
    from_port   = 80
    to_port     = 80
    ip_protocol    = "tcp"
    cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "lb_sq_egress" {
  security_group_id = aws_security_group.lb_sg.id
  from_port   = -1
  to_port     = -1
  ip_protocol    = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

output "load_balancer_url" {
  value = aws_lb.loadbalancer.dns_name
}

