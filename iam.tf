
resource "aws_iam_role" "metabase_ecs_execution_role" {
  name = "metabase_ecs_execution_role_${local.deployment_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "ECSTaskExecutionRolePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

resource "aws_iam_role" "metabase_ecs_task_role" {
  name = "metabase_ecs_task_role_${local.deployment_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
