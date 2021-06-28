provider "aws" {
    region = "us-east-1"
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  enable_deletion_protection = true
  access_logs {
    enabled = false
    bucket  = "aws-bucket"
    prefix  = "test-lb"
  }
}