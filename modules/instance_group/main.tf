provider "aws" {
  shared_config_files      = ["${var.cred_location}/config"]
  shared_credentials_files = ["${var.cred_location}/credentials"]
  region = var.region
}

# === Instance ================================
resource "aws_instance" "temp_vm" {
  ami           = var.image
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
  availability_zone = var.availability_zone
}

# === AMI ================================
resource "aws_ami_from_instance" "apache2" {
  name               = "terraform-apache2"
  source_instance_id = aws_instance.temp_vm.id
}

# === Autoscaling group================================
resource "aws_launch_template" "autoscale_template" {
  image_id        = aws_ami_from_instance.apache2.id
  instance_type  = var.instance_type
  user_data      = filebase64("./startup.sh")
  placement {
    availability_zone = var.availability_zone
  }
  vpc_security_group_ids = var.security_groups # Propably - makes instances avalaibe for loadbalancer
}
resource "aws_autoscaling_group" "autoscale_group" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.autoscale_template.id
      }
    }
  }

  vpc_zone_identifier  = var.vpc_zone_identifiers

  health_check_type   = "EC2"
  health_check_grace_period = 300
}
