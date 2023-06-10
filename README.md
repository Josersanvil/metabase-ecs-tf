# Metabase Deployment in ECS

A Terraform module for deploying [Metabase](https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker#production-installation) using AWS Elastic Container Service (ECS) with Fargate.

The internal database is stored in an RDS Aurora-PostgreSQL Serverless database by default, but can be changed to use an H2 database with an EFS volume mounted to the container (The File System is not managed by this module).

## Usage

Only a VPC ID is required to deploy Metabase. The module will create a new ECS cluster and all the required resources to run Metabase (such as an Application Load Balancer, Target Group, RDS database, etc).

```hcl
data "aws_vpc" "default-vpc" {
  default = true
}

module "metabase" {
  source = "../../modules/metabase"

  vpc_id                            = data.aws_vpc.default-vpc.id
}
```

You can provide other variables to customize the deployment. For example, you can specify a custom domain name with a Route53 hosted zone to create a DNS record pointing to the load balancer and an HTTPS listener with a certificate for that domain name.

```hcl
# The following example would deploy Metabase and make it accessible at https://metabase.example.com
data "aws_route53_zone" "example" {
  name = "example.com"
}

module "metabase" {
  source = "../../modules/metabase"

  vpc_id                            = data.aws_vpc.default-vpc.id
  domain_name                       = data.aws_route53_zone.example.name
  subdomain_name                    = "metabase"
}
```

See all input variables in [variables.tf](variables.tf).

For more advanced usages take a look at the [examples folder](./examples/).

## Deploy

Deploy the infrastructure to AWS just run `terraform apply` and approve the changes after reviewing the generated plan.

## Clean

To clean up the infrastructure created by this module run `terraform destroy` and approve the changes after reviewing the generated plan.

The RDS database will be deleted after the module is destroyed, so make sure to backup the data if you want to keep it.

The EFS volume is not managed by this module, so if you are using it to store the database files, make sure to delete it manually.
