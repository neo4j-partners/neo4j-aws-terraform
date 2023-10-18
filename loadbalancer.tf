resource "aws_lb" "neo4j_lb" {
  name               = "${var.env_prefix}-nlb"
  internal           = false
  load_balancer_type = "network"

  subnets = var.lb_subnets

  tags = {
    "Name"      = "${var.env_prefix}-nlb"
    "Terraform" = true
  }

  lifecycle {
    ignore_changes = [
    ]
  }
}

resource "aws_lb_listener" "neo4j_listener_http" {
  load_balancer_arn = aws_lb.neo4j_lb.arn
  port              = "7474"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.neo4j_http_lb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "neo4j_listener_bolt" {
  load_balancer_arn = aws_lb.neo4j_lb.arn
  port              = "7687"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.neo4j_bolt_lb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "neo4j_http_lb_tg" {
  name     = "${var.env_prefix}-http-tg"
  port     = 7474
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "neo4j_bolt_lb_tg" {
  name     = "${var.env_prefix}-bolt-tg"
  port     = 7687
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "neo4j_http_lb_tg_attachment" {
  count            = var.node_count
  target_group_arn = aws_lb_target_group.neo4j_http_lb_tg.arn
  target_id        = aws_instance.neo4j_instance[count.index].id
  port             = 7474
}

resource "aws_lb_target_group_attachment" "neo4j_bolt_lb_tg_attachment" {
  count            = var.node_count
  target_group_arn = aws_lb_target_group.neo4j_bolt_lb_tg.arn
  target_id        = aws_instance.neo4j_instance[count.index].id
  port             = 7687
}
