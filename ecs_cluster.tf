resource "aws_service_discovery_private_dns_namespace" "metabase_namespace" {
  name = "metabase.${local.deployment_id}"
  vpc  = data.aws_vpc.metabase_vpc.id
}

resource "aws_ecs_cluster" "metabase_cluster" {
  name = "Metabase-${local.deployment_id}"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.metabase_namespace.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "metabase_fargate_capacity_provider" {
  cluster_name       = aws_ecs_cluster.metabase_cluster.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
