variable "load_balancer_name" {
  description = "Name of a custom load balancer. The load balancer must be in the same VPC as VPC id given."
  type        = string
}

variable "domain_name" {
  description = "Route53 domain name to use for exposing the Metabase service. A certificate will be created for this domain name."
  type        = string
}
