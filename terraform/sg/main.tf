provider "aws" {
    region = "us-east-1"
    #  shared_credentials_file = "~/.aws/credentials"
    profile = "default"
}

variable "vpc_id" {
  type = string
  default = "vpc-e0add29b"
}

resource "aws_security_group" "palisade-test-sg" {
  name        = "palisade-test-sg"
  description = "test module for palisade"
  vpc_id      = var.vpc_id 

  ingress {
    from_port   = 0
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}