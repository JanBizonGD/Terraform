variable "image" {
  default = "ami-04b4f1a9cf54c11d0" # Linux/ubuntu
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "desired_capacity" {
  default = 3
}

variable "max_size" {
  default = 3
}

variable "min_size" {
  default = 3
}

variable "security_groups" {
  description = "Security groups for each instance."
  type = list
}

variable "vpc_zone_identifiers" {
  description = "Subnets as a zone idenfires for each instance"
  type = list
}
