# === Autoscaling policies for Airflow Webserver ====

resource "aws_appautoscaling_target" "metabase_target" {
  min_capacity       = var.metabase_service_scale_min_capacity
  max_capacity       = var.metabase_service_scale_max_capacity
  resource_id        = "service/${aws_ecs_cluster.metabase_cluster.name}/${aws_ecs_service.metabase_app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_metabase_target_cpu" {
  name               = "metabase-cpu-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.metabase_target.resource_id
  scalable_dimension = aws_appautoscaling_target.metabase_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.metabase_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.metabase_target]
}

resource "aws_appautoscaling_policy" "ecs_metabase_target_memory" {
  name               = "metabase-memory-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.metabase_target.resource_id
  scalable_dimension = aws_appautoscaling_target.metabase_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.metabase_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70
  }

  depends_on = [aws_appautoscaling_target.metabase_target]
}
