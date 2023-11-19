variable "vpc_id" {
  description = "ID of the VPC where to deploy neo4j"
  type        = string
}

variable "subnet" {
  description = "The subnet in which to deploy the instance"
  type        = string
}

variable "source_security_groups" {
  description = "The source security group IDs traffic should be allowed from"
  type        = list(string)
}

variable "env_prefix" {
  description = "A prefix which is useful for tagging and naming"
  type        = string
}

variable "target_region" {
  description = "The region in which the environment will be deployed"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "The type of EC2 instances to be deployed"
  type        = string
  default     = "t3.medium"
}

variable "ami" {
  type        = string
  description = "The AMI ID for the Neo4j instance(s)"
}

variable "password_secret_name" {
  type        = string
  description = "The name of the AWS secret that will contain the password"
  default     = "neo4j-password"
}

variable "volume_size" {
  type    = number
  default = 32
}
