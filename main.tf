terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket = "terr-05-03-2025"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  shared_config_files      = ["/root/.aws/config"]
  shared_credentials_files = ["/root/.aws/credentials"]
  region = var.aws_region
}

# === Output =================================
output "load_balancer_url" {
  value = module.load_balancer.load_balancer_url
}

# === Modules =================================
module "lb_network_setup" {
  source = "./modules/lb_network_setup"
}
module "instance_group" {
  source = "./modules/instance_group"
  security_groups = [aws_security_group.instance_sg.id]
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

# === List instances in subnet =================================
data "aws_instances" "instances_in_subnet" {
  filter {
    name   = "subnet-id"
    values = [module.lb_network_setup.virtual_subnet_ids[0]]
  }
  depends_on = [module.instance_group.autoscale_group]
}

# === Security groups =================================
resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Allow HTTP traffic"
  vpc_id = module.lb_network_setup.virtual_network_id
}

# Restrict access to load balancer for one ip address
resource "aws_vpc_security_group_ingress_rule" "lb_sq_ingress" {
    security_group_id = aws_security_group.lb_sg.id
    from_port   = 80
    to_port     = 80
    ip_protocol    = "tcp"
    cidr_ipv4 = "87.245.249.103/32"
}
resource "aws_vpc_security_group_ingress_rule" "lb_internal_ingress" {
    security_group_id = aws_security_group.lb_sg.id
    from_port   = 80
    to_port     = 80
    ip_protocol    = "tcp"
    cidr_ipv4 = "10.0.0.0/16"
}

resource "aws_vpc_security_group_egress_rule" "lb_sq_egress" {
  security_group_id = aws_security_group.lb_sg.id
  from_port   = -1
  to_port     = -1
  ip_protocol    = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-security-group"
  description = "Allow HTTP traffic"
  vpc_id = module.lb_network_setup.virtual_network_id
}

resource "aws_vpc_security_group_ingress_rule" "instance_sg_ingress" {
    security_group_id = aws_security_group.instance_sg.id
    from_port   = 80
    to_port     = 80
    ip_protocol    = "tcp"
    cidr_ipv4 = "10.0.0.0/16"
}

resource "aws_vpc_security_group_egress_rule" "instance_sg_egress" {
  security_group_id = aws_security_group.instance_sg.id
  from_port   = -1
  to_port     = -1
  ip_protocol    = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}
