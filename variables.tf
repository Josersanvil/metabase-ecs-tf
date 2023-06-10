variable "vpc_id" {
  description = "The ID of the VPC where the resources will be deployed"
  type        = string
}

variable "metabase_image_tag" {
  description = "The Metabase Docker image tag to use"
  type        = string
  default     = "v0.46.4"
}

variable "extra_environment_variables" {
  description = "Extra environment variables to pass to the Metabase container as a list of objects with name and value attributes."
  type = list(object({
    name  = string
    value = string
  }))
  default = []

  validation {
    # Validate it doesn't contain any reserved environment variables:
    condition = length([for env_var in var.extra_environment_variables : env_var.name if contains([
      "MB_DB_FILE",
      "MB_DB_NAME",
      "MB_DB_HOST",
      "MB_DB_PORT",
      "MB_DB_TYPE",
      "MD_DB_USER",
      "MB_DB_PASS",
    ], env_var.name)]) == 0
    error_message = "The extra_environment_variables variable cannot contain any reserved environment variables"
  }
}

variable "metabase_service_scale_min_capacity" {
  description = "Minimun scaling capacity of the Metabase ECS services"
  type        = number
  default     = 1

  validation {
    condition     = var.metabase_service_scale_min_capacity >= 1
    error_message = "The minimum scaling capacity must be greater than or equal to 1."
  }
}

variable "metabase_service_scale_max_capacity" {
  description = "Maximum scaling capacity of the Metabase ECS services"
  type        = number
  default     = 3
}

variable "metabase_db_acu_min_capacity" {
  description = "Minimum capacity of the RDS database in Aurora Serverless ACUs. Only used when h2_db_file_system_id is not provided."
  type        = number
  default     = 0.5

  validation {
    condition     = var.metabase_db_acu_min_capacity >= 0.5
    error_message = "The minimum capacity must be greater than or equal to 0.5."
  }
}

variable "metabase_db_acu_max_capacity" {
  description = "Maximum capacity of the RDS database in Aurora Serverless ACUs. Only used when h2_db_file_system_id is not provided."
  type        = number
  default     = 4
}

# Advanced parameters:

## To provide an EFS volume to use a persistent H2 database:
variable "h2_db_file_system_id" {
  description = "The EFS file system ID to mount for storing the Metabase H2 database. If not provided, the database will be created as a Postgres RDS database."
  type        = string
  default     = null
}

variable "h2_db_file_system_access_point_id" {
  description = "The access point ID to use when mounting the file system. Required when h2_db_file_system_id is provided."
  type        = string
  default     = null
}

## To provide a Route 53 domain name to expose the Metabase service through a custom domain name:
variable "route_53_domain_name" {
  description = "Route 53 domain name (such as 'myorganization.com') to use for exposing the Metabase service. If not provided, the service will be exposed through the load balancer's DNS name. A certificate will be created for this domain name."
  type        = string
  default     = null
}

variable "subdomain_name" {
  description = "The subdomain name to use for the Metabase URL, such as 'metabase' so the URL would be 'metabase.myorganization.com'. Only used if route_53_domain_name is provided."
  type        = string
  default     = ""
}

## To control the networking of the application on your own:
variable "custom_load_balancer_arn" {
  description = "Provide the ARN of an existing load balancer to use for exposing the Metabase service. If not provided, a new load balancer will be created for you. When provided, the load balancer must be in the same VPC as the one provided in the vpc_id variable. A listener rule is not created automatically for the referenced load balancer nor an ACM certificate when using route_53_domain_name."
  type        = string
  default     = null
}
