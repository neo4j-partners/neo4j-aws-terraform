locals {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

variable "vpc_base_cidr" {
  description = "The base of the address range to be used by the VPC and corresponding Subnets"
  type        = string
  default     = "10.10.0.0/16"
  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/([0-9]|[1-2][0-9]|3[0-2]))$", var.vpc_base_cidr))
    error_message = "Invalid IP address provided for the vpc_base_cidr block variable.  A valid example would be 10.10.0.0/16"
  }
}

variable "ssh_source_cidr" {
  description = "The cidr range which is allowed to connect to the EC2 instances via SSH. Default will be fully open: 0.0.0.0/0"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/([0-9]|[1-2][0-9]|3[0-2]))$", var.ssh_source_cidr))
    error_message = "Invalid IP address provided for the ssh_source_cidr variable.  A valid example would be 0.0.0.0/16"
  }
}

variable "neo4j_source_cidr" {
  description = "The cidr range which is allowed to connect to the neo4j environment. Default will be fully open: 0.0.0.0/0"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/([0-9]|[1-2][0-9]|3[0-2]))$", var.neo4j_source_cidr))
    error_message = "Invalid IP address provided for the vpc_neo4j_source_cidr block variable.  A valid example would be 0.0.0.0/16"
  }
}

variable "env_prefix" {
  description = "A prefix which is useful for tagging and naming"
  type        = string
}

variable "neo4j_version" {
  description = "The version of neo4j to be installed"
  type        = string

  validation {
    condition     = contains(["5"], var.neo4j_version)
    error_message = "The only currently supported value is 5 (for Neo4j version 5).  Development is ongoing for Neo4j v4.4 (LTS)"
  }

  default = 5
}

variable "target_region" {
  description = "The region in which the environment will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "A list containing 3 AZs"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "subnet_qty" {
  description = "The number of subnets in the environment - should remain at 3"
  type        = number
  default     = 3
}

variable "node_count" {
  description = "The number of neo4j instances to be deployed"
  default     = 3
  type        = number

  validation {
    condition = (
      var.node_count > 0 &&
      var.node_count != 2 &&
      var.node_count < 11
    )
    error_message = "node_count can be 1 or between 3 and 10"
  }
}

variable "instance_type" {
  description = "The type of EC2 instances to be deployed"
  type        = string
  default     = "t3.medium"
}

variable "public_key_value" {
  description = "The public SSH key, generated on the the local environment"
}

variable "private_key_path" {
  description = "The location of the private SSH key, generated on the the local environment"
}

variable "install_gds" {
  description = "Determine if GDS is required"
  type        = bool
  default     = false
}

variable "install_bloom" {
  description = "Determine if Bloom is required"
  type        = bool
  default     = false
}

variable "install_apoc" {
  description = "Determine if the APOC library is required"
  type        = bool
  default     = true
}

variable "gds_key" {
  description = "License Key for Graph Data Science"
  type        = string
  default     = "None"
}

variable "bloom_key" {
  description = "License Key for Bloom"
  type        = string
  default     = "None"
}

variable "neo4j_password" {
  description = "Password for the neo4j user"
}

variable "neo4j-ami-list" {
  description = "A map containing the neo4j AMIs"
  //type        = map(string)
  default = {
    "4.4" = {
      "us-east-1" = "ami-0ebd717756e832d9f"
    },

    "5" = {
      "us-east-1"      = "ami-0e400af847eb9a531",
      "us-east-2"      = "ami-0107e71b1207b90c1",
      "us-west-1"      = "ami-01a47d8951b35c272",
      "us-west-2"      = "ami-074caf8265c21fd4d",
      "ca-central-1"   = "ami-07887e0c7c8cd3151",
      "eu-central-1"   = "ami-01321a57a6c5786c4",
      "eu-west-1"      = "ami-0f91decef80d7d93b",
      "eu-west-2"      = "ami-0a7d3edbd43b7eb80",
      "eu-west-3"      = "ami-084419b01954a6223",
      "eu-north-1"     = "ami-05fed050da0ade42e",
      "eu-south-1"     = "ami-02c3742c42b59e7ef",
      "ap-southeast-1" = "ami-09a4e375812f71b6a",
      "ap-southeast-2" = "ami-0a95c0a2258c32e85",
      "ap-southeast-3" = "ami-09093311aa2cb29a8",
      "ap-south-1"     = "ami-0fceddde2778cc2e0",
      "ap-northeast-1" = "ami-0dbecd5269ffad97f",
      "ap-northeast-2" = "ami-0e78f50ef5b1e902b",
      "ap-northeast-3" = "ami-0ff14d64aef37f40d",
      "ap-east-1"      = "ami-05f54d0dc0905041d",
      "sa-east-1"      = "ami-0a431786eba166f75",
      "me-south-1"     = "ami-0c77db260e85bb422",
      "af-south-1"     = "ami-041936db2e9c3abc2",
      "us-gov-east-1"  = "ami-02ed55fa8cb841061",
      "us-gov-west-1"  = "ami-05f0b2155478f825"
    }
  }
}
