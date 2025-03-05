variable "region" {
  description = "AWS region"
  type = string
  default = "us-east-1"
}

variable "cred_location" {
  description = "Credential location to access cloud. It is a folder."
  type = string
  default = "/root/.aws"
}

variable "name" {
  description = "Name of load balancer"
  type = string
  default = "app-lb"
}

variable "security_groups" {
  description = "Security groups for loadbalancer."
  type = list
}

variable "virtual_network" {
  description = "VPC id"
  type = string
}

variable "subnets" {
  description = "Subnet list"
  type = list
}

variable "instances" {
  description = "Instances for balancing"
  type = list
}
