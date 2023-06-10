terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      environment            = "Development"
      application            = "Metabase"
      managed_by             = "Terraform"
      metabase_deployment_id = module.metabase.deployment_id
    }
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_route53_zone" "domain" {
  name = var.domain_name
}

data "aws_lb" "load_balancer" {
  name = var.load_balancer_name
}

data "aws_lb_listener" "lb_https_listener" {
  load_balancer_arn = data.aws_lb.load_balancer.arn
  port              = 443
}

resource "aws_lb_listener_rule" "metabase_listener_rule" {
  listener_arn = data.aws_lb_listener.lb_https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = module.metabase.metabase_target_group_arn
  }

  condition {
    host_header {
      values = ["metabase.${var.domain_name}"]
    }
  }
}

module "metabase" {
  source = "github.com/josersanvil/metabase-ecs-tf"

  vpc_id                   = data.aws_vpc.default_vpc.id
  route_53_domain_name     = data.aws_route53_zone.domain.name
  subdomain_name           = "metabase"
  custom_load_balancer_arn = data.aws_lb.load_balancer.arn
}
