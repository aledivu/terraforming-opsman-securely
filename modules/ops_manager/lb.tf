// Allow access to OpsMan
resource "aws_lb" "ops_man" {
  name                             = "${var.env_name}-ops-man"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  internal                         = false
  subnets                          = ["${var.public_subnet_ids}"]
}

resource "aws_lb_listener" "ops_man_443" {
  load_balancer_arn = "${aws_lb.ops_man.arn}"
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ops_man_443.arn}"
  }
}

resource "aws_lb_target_group" "ops_man_443" {
  name     = "${var.env_name}-ops-man-tg-443"
  port     = 443
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 6
    unhealthy_threshold = 6
    interval            = 10
    protocol            = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "ops_man_443" {
  target_group_arn = "${aws_lb_target_group.ops_man_443.arn}"
  target_id        = "${aws_instance.ops_manager.id}"
  port             = 443
}
