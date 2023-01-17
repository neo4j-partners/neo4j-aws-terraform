# neo4j-aws-terraform

This repository hosts a terraform module for the installation of an environment in AWS EC2, running neo4j.  

## Usage
The terraform code hosted in this repository can be easily used by creating a parent module on your local machine, in a main.tf file as shown below.
(More information about terraform modules can be found on [this](https://developer.hashicorp.com/terraform/language/modules) page)

Note the `source` parameter can be used to either point directly to this repository or a local copy of the code.

The command [`ssh-keygen`](https://linux.die.net/man/1/ssh-keygen) can be used to generate a keypair.  The private key should not be shared, and its file location should be the value for `private_key_path`.  The contents of the public key should be given as the value for `public_key_path`

~~~
#main.tf file for deploying neo4j-terraform
module "neo4j-environment" {
  source         = "github.com/neo4j/neo4j-aws-terraform/tree/main"
  //source       = "../neo4j-terraform"

  //Required values (no defaults are provided)
  neo4j_password   = "pw_for_neo4j_user"
  public_key_value = "ssh-rsa AAAAB3NzaC1A.....b+oTz7tb0WF2aiOPp0="
  private_key_path = "~/.ssh/my-ssh-key"

  //The following Optional values can be omitted if the defaults are satisfactory.

  //Default is "t3.medium"
  instance_type = "t3.medium"

  //Default is 3. Valid values are 1, or 3 -> 10 (inclusive)
  node_count = 3

  //Default is "10.0.0.0/16"
  vpc_base_cidr = "10.0.0.0/16"

  //Default is "0.0.0.0/0"
  ssh_source_cidr   = "0.0.0.0/0"
  neo4j_source_cidr = "0.0.0.0/0"

  //Default is false
  install_gds = "false"

  //Default is false
  install_bloom = "false"

  //Default is true
  install_apoc = "true"

  //Default is "neo4j-tf-cloud"
  env_prefix = "my-neo4j-environment"

  //Default is "us-east-1"
  target_region = "us-east-1"

  //Default is "None"
  gds_key = "None"

  //Default is "None"
  bloom_key = "None"
}

output "ssh_commands" {
  value = module.neo4j-environment.ssh_commands
}

output "neo4j_browser_url" {
  value = module.neo4j-environment.neo4j_browser_url
}
~~~

## Prerequisites

In order to use this module, terraform needs to be properly installed and configured.  Whilst this is out of the scope of this README file, an example provider.tf file is shown below.  The [official terraform documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) explains how to get terraform up and running on a local machine.  Alternatively, [Terraform Cloud](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started) is another option.

~~~
//Configure the terraform backend (S3) and aws provider
terraform {
  backend "s3" {
    bucket  = "<s3-bucketname goes here>"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    profile = "product-na"

  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

//Specify which AWS region and profile should be used by default
provider "aws" {
  region  = "us-east-1"
  profile = "product-na"
}
~~~

## Limitations

Currently, the following limitations apply:
 - Only Neo4j v5 is supported.  Support for 4.4 will follow.
 - The addition of nodes to a neo4j cluster is currently not supported.  The desired number of nodes in a cluster must be selected prior to deployment, using the node_count variable
 - SSL (https) has not been included in this initial release
 - The environment uses a network load balancer in AWS.  This means the EC2 instances will also be directly accessible from whichever address ranges are configure in var.ssh_source_cidr
