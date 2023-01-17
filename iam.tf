resource "aws_iam_role" "neo4j_ec2_role" {
  name = "${var.env_prefix}-role"
  //assume_role_policy = local.assume_role_policy

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

resource "aws_iam_instance_profile" "neo4j_instance_profile" {
  name = "${var.env_prefix}-profile"
  role = aws_iam_role.neo4j_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_ro_policy_attachment" {
  role       = aws_iam_role.neo4j_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "neo4j_nlb_tagging_policy" {
  role       = aws_iam_role.neo4j_ec2_role.name
  policy_arn = aws_iam_policy.neo4j_nlb_tagging_policy.arn
}

resource "aws_iam_policy" "neo4j_nlb_tagging_policy" {
  name        = "neo4j_nlb_tagging_policy"
  description = "Policy for tagging Network Load Balancer"
  policy      = data.aws_iam_policy_document.neo4j_nlb_tagging_policy_document.json
}

data "aws_iam_policy_document" "neo4j_nlb_tagging_policy_document" {
  depends_on = [
    aws_lb.neo4j_lb
  ]

  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancingv2:AddTags",
      "elasticloadbalancingv2:DescribeTags",
    ]
    resources = [
      aws_lb.neo4j_lb.arn
    ]
  }
}
