/*resource "aws_cloudwatch_log_group" "one" {
  name = var.tags["Environment"]
}

resource "aws_prometheus_workspace" "one" {
  alias = var.tags["Environment"]
  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.one.arn}:*"
  }
}*/


# create a service role for ec2 
resource "aws_iam_role" "prometheus_instance" {
  name = "prometheus-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)
  inline_policy {
    name = "prometheus_ec2"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:Describe*"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["ssm:SendCommand", "ssm:List*", "ssm:Get*"]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["autoscaling:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

# provide ec2 access to the registry
resource "aws_iam_role_policy_attachment" "prometheus_instance_ecr" {
  role       = aws_iam_role.prometheus_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "prometheus-instance-profile"
  role = aws_iam_role.prometheus_instance.name
}

# --------------------- SECURITY GROUP ---------------------------------------

resource "aws_security_group" "prometheus" {
  name        = "${replace(local.name_prefix, "_", "-")}-sg-prometheus"
  description = "Allow Prometheus and Grafana from VPC"
  vpc_id      = aws_vpc.one.id
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.one.cidr_block] #via IPv4 only from vpc
    ipv6_cidr_blocks = [aws_vpc.one.ipv6_cidr_block]
  }
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.one.cidr_block] #via IPv4 only from vpc
    ipv6_cidr_blocks = [aws_vpc.one.ipv6_cidr_block]
  }
}

# ----------------------------------------------------------------------------

resource "aws_instance" "prometheus" {
  count             = 1
  ami               = data.aws_ami.ubuntu24.id
  subnet_id         = aws_subnet.workers[0].id
  instance_type     = "t2.micro"
  security_groups   = [
    aws_security_group.public.id,
    aws_security_group.prometheus.id
  ]
  user_data         = templatefile("user_data.yaml.tpl", {
    prometheus_ips  = null
    app_stack       = "stack-prometheus"
    ssh_key_pub     = var.ssh_key_pub,
    ssh_key_private = var.ssh_key_private,
    region          = var.region,
    registry        = var.registry,
    env             = var.tags["Environment"]
  })
  #associate_public_ip_address = false
  associate_public_ip_address = true # needed by codedeploy
  iam_instance_profile = aws_iam_instance_profile.prometheus.name

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "prometheus-${count.index+1}"
  }
}

resource "aws_route53_record" "prometheus" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "prom.demo.local"
  type    = "A"
  ttl     = 300
  records = aws_instance.prometheus[*].private_ip
}