output "deployment_id" {
  description = "The randomly generated deployment ID. Can be used to identify the resources created by this module."
  value       = random_string.deployment_id.result
}

output "rds_master_user_secret_arn" {
  description = "ARN of the secret containing the master user password for the Metabase internal database. Not available if using an H2 database."
  value       = local.create_rds_database ? aws_rds_cluster.metabase_db[0].master_user_secret[0].secret_arn : null
}

output "metabase_target_group_arn" {
  description = "The ARN of the Metabase target group. Can be used to create a listener for the load balancer."
  value       = aws_lb_target_group.metabase_target.arn
}

output "metabase_ecs_task_role_arn" {
  description = "The ARN of the Metabase ECS task role. Can be used to attach custom policies to the role."
  value       = aws_iam_role.metabase_ecs_task_role.arn
}

output "metabase_app_hostname" {
  description = "The hostname of the Metabase application."
  value       = var.route_53_domain_name == null ? var.custom_load_balancer_arn == null ? aws_lb.metabase-alb[0].dns_name : data.aws_lb.custom_lb[0].dns_name : aws_route53_record.metabase-record[0].fqdn
}
