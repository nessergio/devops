provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "dns_aaaa_record_set" "nlb" {
  depends_on = [ aws_lb.one ]
  host = aws_lb.one.dns_name
}

resource "cloudflare_record" "a" {
  depends_on = [ aws_lb.one ]
  count   = local.n_zones
  zone_id = var.cloudflare_zone_id
  name    = local.dns_name
  value   = aws_eip.nlb[count.index].public_ip
  type    = "A"
  ttl     = 60
}

resource "cloudflare_record" "aaaa" {
  depends_on = [ aws_lb.one ]
  count   = local.n_zones
  zone_id = var.cloudflare_zone_id
  name    = local.dns_name
  value   = data.dns_aaaa_record_set.nlb.addrs[count.index]
  type    = "AAAA"
  ttl     = 60
}


