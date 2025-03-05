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
