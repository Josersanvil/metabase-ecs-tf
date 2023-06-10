resource "aws_ecs_service" "metabase_app" {

  name                               = "Metabase"
  cluster                            = aws_ecs_cluster.metabase_cluster.arn
  task_definition                    = var.h2_db_file_system_id == null ? aws_ecs_task_definition.metabase_task_definition_rds[0].arn : aws_ecs_task_definition.metabase_task_definition_efs[0].arn
  platform_version                   = "LATEST"
  propagate_tags                     = "TASK_DEFINITION"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 360

  capacity_provider_strategy {
    base              = "0"
    capacity_provider = "FARGATE"
    weight            = "1"
  }

  deployment_circuit_breaker {
    enable   = "true"
    rollback = "true"
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    container_name   = "metabase"
    container_port   = "3000"
    target_group_arn = aws_lb_target_group.metabase_target.arn
  }

  network_configuration {
    assign_public_ip = "true"
    security_groups  = [aws_security_group.metabase_web_security_group.id]
    subnets          = local.metabase_vpc_subnets_ids
  }
}
