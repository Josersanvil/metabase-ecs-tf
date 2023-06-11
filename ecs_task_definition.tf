locals {
  task_definition_cpu     = 512
  task_definition_memory  = 2048
  task_execution_role_arn = aws_iam_role.metabase_ecs_execution_role.arn
  task_role_arn           = aws_iam_role.metabase_ecs_task_role.arn
  container_image         = "metabase/metabase:${var.metabase_image_tag}"
  container_port_mappings = [
    {
      appProtocol   = "http"
      name          = "metabase-3000-tcp"
      protocol      = "tcp"
      containerPort = 3000
      hostPort      = 3000
    }
  ]
  container_log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.metabase_logs.name
      awslogs-region        = data.aws_region.current.name,
      awslogs-stream-prefix = "metabase"
    },
  }
  container_health_check = {
    command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
    interval    = 30
    retries     = 3
    startPeriod = 60
    timeout     = 5
  }
}

resource "aws_cloudwatch_log_group" "metabase_logs" {
  name              = "/airflow/${local.deployment_id}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "metabase_task_definition_efs" {
  count = local.create_rds_database ? 0 : 1

  cpu                      = local.task_definition_cpu
  memory                   = local.task_definition_memory
  execution_role_arn       = local.task_execution_role_arn
  task_role_arn            = local.task_role_arn
  family                   = "Metabase-h2-efs-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name             = "metabase"
      essential        = true
      image            = local.container_image
      portMappings     = local.container_port_mappings
      logConfiguration = local.container_log_configuration,
      mountPoints = [
        {
          containerPath = "/mnt/"
          readOnly      = false
          sourceVolume  = "metabase-volume"
        }
      ],
      environment = concat(
        [
          {
            name  = "MB_DB_FILE",
            value = "/mnt/metabase.db"
          },
          {
            name  = "MB_DB_TYPE",
            value = "h2"
          }
        ],
        var.extra_environment_variables
      ),
    },
  ])

  volume {
    name = "metabase-volume"

    efs_volume_configuration {
      file_system_id     = var.h2_db_file_system_id
      root_directory     = "/"
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.h2_db_file_system_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}


resource "aws_ecs_task_definition" "metabase_task_definition_rds" {
  count = local.create_rds_database ? 1 : 0

  cpu                      = local.task_definition_cpu
  memory                   = local.task_definition_memory
  execution_role_arn       = local.task_execution_role_arn
  task_role_arn            = local.task_role_arn
  family                   = "Metabase-postgres-rds-${local.deployment_id}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name             = "metabase"
      essential        = true
      image            = local.container_image
      portMappings     = local.container_port_mappings
      logConfiguration = local.container_log_configuration,
      environment = concat(
        [
          {
            name  = "MB_DB_NAME",
            value = local.db_name
          },
          {
            name  = "MB_DB_HOST"
            value = local.db_hostname
          },
          {
            name  = "MB_DB_PORT",
            value = tostring(local.db_port)
          },
          {
            name  = "MB_DB_TYPE",
            value = "postgres"
          },
          {
            name  = "MB_DB_USER",
            value = local.db_username,
          },
          {
            name  = "MB_DB_PASS",
            value = local.db_password,
          }
        ],
        var.extra_environment_variables
      )
    }
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

