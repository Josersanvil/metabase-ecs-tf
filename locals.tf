data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_security_group" "DefaultWebServices_sg" {
  name = "DefaultWebServices"
}


locals {
  common_tags = {
  }
  default_vpc_id          = data.aws_vpc.default_vpc.id
  default_vpc_subnets_ids = data.aws_subnets.default_vpc_subnets.ids
}

