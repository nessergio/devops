# Assign an Elastic IP 
resource "aws_eip" "nlb" {
  count = local.n_zones
  domain = "vpc"
}

resource "aws_lb" "one" {
  name               = "${replace(local.name_prefix, "_", "-")}-nlb"
  load_balancer_type = "network"
  internal           = false
  ip_address_type    = "dualstack"
  enable_cross_zone_load_balancing = true
  dynamic "subnet_mapping" {
    for_each = range(local.n_zones)
    content {
      subnet_id     = aws_subnet.workers[subnet_mapping.key].id
      allocation_id = aws_eip.nlb[subnet_mapping.key].id
    }
  }
  tags = { Name = "${local.name_prefix}_nlb" }
  depends_on = [ aws_subnet.workers ]
}

resource "aws_lb_target_group" "http" {
  name        = "${replace(local.name_prefix, "_", "-")}-http"
  vpc_id      = aws_vpc.one.id
  port        = 80
  protocol    = "TCP"
  target_type = "instance"

  /*health_check {
	enabled  = true
	interval = 30
	port     = 22
  }*/
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.one.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}
