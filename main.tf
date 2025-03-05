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
module "load_balancer" {
  source = "./modules/load_balancer"
  security_groups = [aws_security_group.lb_sg.id]
  virtual_network = module.lb_network_setup.virtual_network_id
  subnets = module.lb_network_setup.virtual_subnet_ids
  instances = data.aws_instances.instances_in_subnet.ids
}

data "aws_instances" "instances_in_subnet" {
  filter {
    name   = "subnet-id"
    values = [module.lb_network_setup.virtual_subnet_ids[0]]
  }
  depends_on = [module.instance_group.autoscale_group]
}
moved {
  from = aws_lb.loadbalancer
  to = module.load_balancer.aws_lb.loadbalancer
}
moved {
  from = aws_lb_target_group.app_target_group
  to = module.load_balancer.aws_lb_target_group.app_target_group
}
moved {
  from = aws_lb_listener.http_listener
  to = module.load_balancer.aws_lb_listener.http_listener
}
moved {
  from = aws_lb_target_group_attachment.asg_attachment
  to = module.load_balancer.aws_lb_target_group_attachment.asg_attachment
}

resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Allow HTTP traffic"
  vpc_id = module.lb_network_setup.virtual_network_id
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
  value = module.load_balancer.load_balancer_url
}

