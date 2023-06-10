# Metabase Deployment with an EFS volume

An example of how to deploy Metabase using an EFS volume to store the H2 database file.

Providing the module with an EFS volume will make it use an H2 database instead of an RDS database.

An EFS access point must also be provided to allow the container to mount the volume. The example shows how to create an access point with the required permissions and with a subdirectory in the path `/metabase` to store the database file.

## Requirements

The following variables must be provided:

- `file_system_id`: The ID of the EFS file system to use. It must be created outside of this module (like in the AWS Console for example or in another Terraform resource).
