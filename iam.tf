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
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    aws_iam_policy.cw_retention.arn,
  ]
}

resource "aws_iam_policy" "cw_retention" {
  name        = "CloudWatchAgentPutLogsRetention"
  description = "Allow the CW agent to change retention policies"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:PutRetentionPolicy",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "neo4j_ec2_role" {
  name               = "${var.env_prefix}-role"
  assume_role_policy = local.assume_role_policy
}

resource "aws_iam_instance_profile" "neo4j_instance_profile" {
  name = "${var.env_prefix}-profile"
  role = aws_iam_role.neo4j_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.neo4j_ec2_role.name
  policy_arn = element(local.role_policy_arns, count.index)
}
