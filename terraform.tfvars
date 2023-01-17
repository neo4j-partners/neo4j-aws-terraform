//Desired version of Neo4j.  Valid values are 5 or 4.4
neo4j_version = 5

//Desired number of EC2 instances.  Valid values are 1, or 3 -> 10
node_count = 4

//The Base CIDR block for the VPC.  Must be a /16
vpc_base_cidr = "10.123.0.0/16"

//A prefix for the environment name which will be used when tagging instances
env_prefix = "neo4j-tf-cloud"

//The AWS region in which the resources (and Neo4j) will be installed
target_region = "us-east-1"

//Neo4j component selection.  Values are boolean.
install_gds   = false
install_bloom = false
install_apoc  = true

//License Keys for GDS and Bloom, if applicable
//gds_key   = "None"
//bloom_key = "None"

//The Password for the neo4j user
neo4j_password = "TestPW123"

//The class of AWS EC2 Instances to use in the environment
instance_type = "t3.medium"

//Path to an SSH key which will be required in order to connected to the EC2 instances (via SSH)
//Generate locally with ssh-keygen and paste
public_key_value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCg6p4wT8NYooUHKlcQrta/D4XkPgbYi9tpejs4/OVU2FDgthgnxJZxVBHy6gUQvroAkZ9mGyqIBkjXN3SJG8OfPdlQQIwcmsIJwE2RU8vmO1NP7Hlh9yfq/gNvF6OA0rQEG6Z4dC9ho/BKMoWUWvXPkT9xVOAZPf0Q7qvG4qUr0XD3Dp1brwOTU25dP0rWzRwOzH+bjBPsQdym9oYfT80KKgutxSZVr+AU5JIyRoLKKV3vjXmQtPoglVvvfYvBezRwiA1TtuS5hBc7cLWw6iHKvg1jWW3QH+fDWowC5d4gNknnwRVdMIojJd+/M+UwLL8FUDdXAwPDHw9mqIi2BMNJykbSweuaPKJLecClNcAZ8MaRmTUaTrb4wBb3GmPVpWuMDVdS2Uf+ii6hgg9mDW88oRABUEt/tpGPSRsP7ctUpvpW8EarbEUYp3h/9rSNZ0NOWIxeZbx4Zn+I/7jhwppl1SSQJodolhkK2nRkWqibPGb9ub+oTz7tb0WF2aiOPp0="
private_key_path = "~/.ssh/aws-test"