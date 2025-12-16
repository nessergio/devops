data "aws_iam_policy_document" "codedeploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

# create a service role for codedeploy
resource "aws_iam_role" "codedeploy_service" {
  name = "codedeploy-service-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role_policy.json # (not shown)
}

# attach AWS managed policy called AWSCodeDeployRole
# required for deployments which are to an EC2 compute platform
resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = "${aws_iam_role.codedeploy_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_codedeploy_app" "one" {
  compute_platform = "Server"
  name             = "${local.name_prefix}_app"
}

resource "aws_codedeploy_deployment_group" "one" {

  app_name                    = aws_codedeploy_app.one.name
  deployment_group_name       = "${local.name_prefix}_deployment"
  service_role_arn            = aws_iam_role.codedeploy_service.arn
  autoscaling_groups          = [ aws_autoscaling_group.workers.name ]
  deployment_config_name      = "CodeDeployDefault.OneAtATime"

  deployment_style {
    # deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.http.name
    }
  }

}