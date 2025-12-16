data "aws_ami" "ubuntu24" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/*24.04*amd64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "worker_instance" {
  name = "worker-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)
}

# provide ec2 access to s3 bucket to download revision. This role is needed by the CodeDeploy agent on EC2 instances.
resource "aws_iam_role_policy_attachment" "instance_profile_codedeploy" {
  role       = aws_iam_role.worker_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# provide ec2 access to the registry
resource "aws_iam_role_policy_attachment" "instance_profile_ecr" {
  role       = aws_iam_role.worker_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# provide SSM capability
resource "aws_iam_role_policy_attachment" "instance_profile_ssm_managed" {
  role       = aws_iam_role.worker_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy"
}
# sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

resource "aws_iam_instance_profile" "worker" {
  name = "worker-instance-profile"
  role = aws_iam_role.worker_instance.name
}

resource "aws_launch_configuration" "worker" {
  name_prefix                 = "${local.name_prefix}_worker"
  image_id                    = data.aws_ami.ubuntu24.image_id
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.public.id]
  user_data                   = templatefile("user_data.yaml.tpl", {
    prometheus_ips  = aws_instance.prometheus[*].private_ip
    app_stack       = "stack-worker"
    ssh_key_pub     = var.ssh_key_pub,
    ssh_key_private = var.ssh_key_private,
    region          = var.region,
    registry        = var.registry,
    env             = var.tags["Environment"]
  })
  #associate_public_ip_address = false
  associate_public_ip_address = true # needed by codedeploy
  iam_instance_profile = aws_iam_instance_profile.worker.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "workers" {
  name_prefix          = "${local.name_prefix}_worker_asg"
  launch_configuration = aws_launch_configuration.worker.id
  max_size             = 6
  min_size             = 1
  desired_capacity     = 2
  
  # Target groups need to be registered in autoscaling group
  target_group_arns = [aws_lb_target_group.http.arn]

  vpc_zone_identifier = [for subnet in aws_subnet.workers : subnet.id] #[aws_subnet.public.id]

  tag {
    key = "worker"
    value = true
    propagate_at_launch = true
  }
}