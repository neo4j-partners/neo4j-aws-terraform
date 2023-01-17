# neo4j-terraform

A terraform module for the installation of an environment in EC2, running neo4j.

## usage
The module can be used by creating a parent module, as follows:

~~~
module "neo4j-environment" {
  source = "../neo4j-tf-module"
  //source           = "github.com/edrandall-dev/neo4j-tf-module"
  node_count         = "3"
  env_name           = "First Test Neo4j Env"
  vpc_base_cidr      = "10.123.0.0/16"
  env_prefix         = "neo4j-test-mod"
  target_region      = "us-east-1"
  availability_zones = ["a", "b", "c"]

  install_gds = "true"
  install_bloom = "true"
  gds_key= "this-is-the-gds-key"
  bloom_key = "this-is-the-bloom-key"
  neo4j_password = "TestPW123!"
  install_apoc = "true"

  instance_type    = "t3.micro"
  public_key_path  = "~/.ssh/aws-test.pub"
  private_key_path = "~/.ssh/aws-test"
}

output "ssh_commands" {
  value = module.neo4j-environment.ssh_commands
}
~~~

#Prerequisites

Both AWS and Terraform commands need to be installed and properly configured before deploying, an example provider.tf file is shown below:

~~~
//Configure the terraform backed and aws provider
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
