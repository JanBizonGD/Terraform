# variable "aws_key_id" {
#   description = "Key id to authenticate in aws cloud"
#   type = string
# }
# variable "aws_secret" {
#   description = "AWS secret to authenticate in aws cloud"
#   type = string
# }
variable "aws_region" {
  description = "AWS region"
  type = string
  default = "us-east-1"
}
variable "instance_type" {
    description = "AWS instance type"
    type = string
    default = "t3.micro"
}
