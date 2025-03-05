provider "aws" {
  shared_config_files      = ["${var.cred_location}/config"]
  shared_credentials_files = ["${var.cred_location}/credentials"]
  region = var.aws_region
}

# === VPC ======================================
resource "aws_vpc" "this" {
    cidr_block = "10.0.0.0/16"
}

# === Subnets ======================================
resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}
resource "aws_subnet" "this2" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
}

# === Gateway ======================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

# === Route Table ======================================
resource "aws_route_table" "default_route" {
  vpc_id = aws_vpc.this.id
}

# Add a Route to the Route Table for Internet access
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.default_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.default_route.id
}
# ==================================================
