data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "metabase_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "metabase_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "random_string" "deployment_id" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  deployment_id            = random_string.deployment_id.result
  metabase_vpc_id          = data.aws_vpc.metabase_vpc.id
  metabase_vpc_cidr_block  = data.aws_vpc.metabase_vpc.cidr_block
  metabase_vpc_subnets_ids = data.aws_subnets.metabase_vpc_subnets.ids

  create_rds_database = var.h2_db_file_system_id == null ? true : false
}

data "aws_secretsmanager_secret_version" "metabase_db_password" {
  count = local.create_rds_database ? 1 : 0

  secret_id = aws_rds_cluster.metabase_db[0].master_user_secret[0].secret_arn
}

locals {
  db_name     = local.create_rds_database ? aws_rds_cluster.metabase_db[0].database_name : null
  db_hostname = local.create_rds_database ? aws_rds_cluster.metabase_db[0].endpoint : null
  db_port     = local.create_rds_database ? aws_rds_cluster.metabase_db[0].port : null
  db_username = local.create_rds_database ? aws_rds_cluster.metabase_db[0].master_username : null
  db_password = local.create_rds_database ? jsondecode(data.aws_secretsmanager_secret_version.metabase_db_password[0].secret_string)["password"] : null
}
