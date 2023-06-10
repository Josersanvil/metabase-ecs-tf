resource "aws_security_group" "metabase_web_security_group" {
  name        = "metabase_web_sg_${local.deployment_id}"
  description = "Allows access to HTTP and HTTPS from the web and full access within the VPC"
  vpc_id      = local.metabase_vpc_id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }

  ingress {
    description = "Allows access to the Airflow web server using HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "443"
  }

  ingress {
    description = "Allows access to the Airflow web server using HTTP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "80"
    protocol    = "tcp"
    self        = "false"
    to_port     = "80"
  }

  ingress {
    description = "Allows all traffic coming from the VPC"
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
    cidr_blocks = [local.metabase_vpc_cidr_block]
  }

  tags = {
    Name = "metabase-web-sg-${local.deployment_id}"
  }
}
