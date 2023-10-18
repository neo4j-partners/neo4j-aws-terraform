variable "vpc_id" {
  description = "ID of the VPC where to deploy neo4j"
  type        = string
}

variable "instance_subnets" {
  description = "A list of subnets (IDs) in which to deploy the EC2 instances"
  type        = list(string)
}

variable "lb_subnets" {
  description = "A list of subnets (IDs) in which to deploy the load balancer"
  type        = list(string)
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

variable "ami" {
  type        = string
  description = "The AMI ID for the Neo4j instance(s)"
}
