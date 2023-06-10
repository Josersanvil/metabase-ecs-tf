# Metabase Deployment with a custom load balancer in HTTPS

An example of how to deploy Metabase using a custom load balancer and providing a certificate for HTTPS.

Deploying Metabase with a custom load balancer allows you to use a load balancer managed outside of this module, which can be useful if you don't want to provide an extra load balancer just for Metabase and instead want to use an existing one.

## Requirements

The following variables must be provided:

- `domain_name`: A domain name to use for the Metabase URL. It must be a valid domain name and have a hosted zone in Route53.
- `load_balancer_name`: The name of the Load Balancer to use. It must be created outside of this module (like in the AWS Console for example or in another Terraform resource), be in the default VPC and have an HTTPS (port 443) listener with a valid certificate for the domain name provided.
