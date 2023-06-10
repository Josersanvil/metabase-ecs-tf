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

data "aws_vpc" "default-vpc" {
  default = true
}

data "aws_efs_file_system" "file_system" {
  file_system_id = var.file_system_id
}

resource "aws_efs_access_point" "access_point" {
  file_system_id = data.aws_efs_file_system.file_system.id

  root_directory {
    path = "/metabase"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }
}

module "metabase" {
  source = "github.com/josersanvil/metabase-ecs-tf"

  vpc_id                            = data.aws_vpc.default-vpc.id
  subdomain_name                    = "metabase"
  h2_db_file_system_id              = data.aws_efs_file_system.file_system.id
  h2_db_file_system_access_point_id = aws_efs_access_point.access_point.id
}
