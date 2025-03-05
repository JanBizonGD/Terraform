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

resource "aws_instance" "temp_vm" {
  ami           = "ami-04b4f1a9cf54c11d0" # Linux/ubuntu
  instance_type = var.instance_type
  tags = {
    Name = "TemporaryVM"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt install -y apache2
              echo "<html><body><h1>Server: $(hostname)</h1></body></html>" > /var/www/html/index.html
              sudo service apache2 start
              EOF
  availability_zone = "${var.aws_region}a"
}

resource "aws_ami_from_instance" "apache2" {
  name               = "terraform-apache2"
  source_instance_id = aws_instance.temp_vm.id
}
# ================================

resource "aws_launch_template" "autoscale_template" {
  image_id        = aws_ami_from_instance.apache2.id #aws_ami.server_image.id
  instance_type  = var.instance_type
  user_data      = filebase64("./startup.sh")
  placement {
    availability_zone = "${var.aws_region}a"
  }
  vpc_security_group_ids = [aws_security_group.lb_sg.id] # Propably - makes instances avalaibe for loadbalancer
}

resource "aws_autoscaling_group" "autoscale_group" {
  desired_capacity     = 3
  max_size             = 3
  min_size             = 3
 # launch_configuration = aws_launch_configuration.app_launch_config.id
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.autoscale_template.id
      }
    }
  }

  vpc_zone_identifier  = [module.lb_network_setup.virtual_subnet_ids[0]] #[aws_subnet.instance_subnet1.id]

  health_check_type   = "EC2"
  health_check_grace_period = 300
}

data "aws_instances" "instances_in_subnet" {
  filter {
    name   = "subnet-id"
    values = [module.lb_network_setup.virtual_subnet_ids[0]] #[aws_subnet.instance_subnet1.id]
  }
  depends_on = [ aws_autoscaling_group.autoscale_group ]
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

