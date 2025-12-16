output "public_ip_addr" {
  value = aws_eip.nlb[*].public_ip
}

output "public_ipv6_addr" {
  value = data.dns_aaaa_record_set.nlb.addrs
}

output "prometheus_addr" {
  value = aws_instance.prometheus[*].public_ip
}
