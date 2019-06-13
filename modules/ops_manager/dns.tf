resource "aws_route53_record" "ops_manager_attached_eip" {
  name    = "pcf.${var.env_name}.${var.dns_suffix}"
  zone_id = "${var.zone_id}"
  type    = "A"
  ttl     = 300
  count   = 0

  records = ["${coalesce(join("", aws_eip.ops_manager_attached.*.public_ip), aws_instance.ops_manager.private_ip)}"]
}

resource "aws_route53_record" "ops_manager_unattached_eip" {
  name    = "pcf.${var.env_name}.${var.dns_suffix}"
  zone_id = "${var.zone_id}"
  type    = "A"

  alias {
    name                   = "${aws_lb.ops_man.dns_name}"
    zone_id                = "${aws_lb.ops_man.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "optional_ops_manager" {
  name    = "pcf-optional.${var.env_name}.${var.dns_suffix}"
  zone_id = "${var.zone_id}"
  type    = "A"
  ttl     = 300
  count   = 0

  records = ["${coalesce(join("", aws_eip.optional_ops_manager.*.public_ip), aws_instance.optional_ops_manager.private_ip)}"]
}
