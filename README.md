# neo4j-terraform

A terraform module for the installation of an environment in EC2, running neo4j.

## usage
The terraform code hosted here can be easily used by creating a parent module on your local machine, with the following contents:
(More information about terraform modules can be found on [this](https://developer.hashicorp.com/terraform/language/modules) page)

~~~
module "neo4j-environment" {
  //source             = "github.com/neo4j/neo4j-terraform/tree/main"
  source = "../neo4j-terraform"

  //Required values (no defaults are provided)
  neo4j_password   = "pw_for_neo4j_user"
  instance_type    = "t3.medium"
  public_key_value = "ssh-rsa AAAAB3NzaC1AAABgQCg....p3h/9rSNZ0NOWIxeZbx4Zn+I/7jhwppl1SSQJodolhkK2nRkWqibPGb9ub+oTz7tb0WF2aiOPp0="
  private_key_path = "~/.ssh/my-ssh-key"

  //The following Optional values can be removed or commented if defaults are satisfactory.

  //Default is 3 . Valid values are 1, or 3 -> 10 (inclusive)
  node_count = 3

  //Default is "10.0.0.0/16"
  vpc_base_cidr = "10.0.0.0/16"

  //Default is false
  install_gds = "true"

  //Default is false
  install_bloom = "true"

  //Default is true
  install_apoc = "true"

  //Default is "neo4j-tf-cloud"
  env_prefix = "my-neo4j-environment

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

Both AWS and Terraform commands need to be installed and properly configured before deploying, an example provider.tf file is shown below:

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
