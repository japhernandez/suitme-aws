resource "aws_ecr_repository" "frontend" {
  name = "frontend"
}

resource "aws_iam_role" "frontend_task_execution_role" {
  name = "frontend-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "frontend_task_execution_policy_attachment" {
  role       = aws_iam_role.frontend_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  execution_role_arn       = aws_iam_role.frontend_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  container_definitions = templatefile("${abspath(path.root)}/../taskdef.json", {
    IMAGE_PATH   = aws_ecr_repository.frontend.repository_url
  })
}

resource "aws_security_group" "frontend_task" {
  name   = "frontend-task-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend-task-sg"
  }
}

resource "aws_ecs_service" "frontend" {
  name                               = "frontend"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.frontend.arn
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  desired_count                      = 2

  network_configuration {
    subnets         = aws_subnet.apps[*].id
    security_groups = [aws_security_group.frontend_task.id]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 9000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb.alb]
}

resource "aws_alb_target_group" "frontend" {
  name        = "frontend-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/api/v1/health"
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.frontend.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/*"]
    }
  }
}

resource "aws_codebuild_project" "frontend" {
  name         = "frontend"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "./buildspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:3.0"
    type         = "LINUX_CONTAINER"

    // Use privileged mode otherwise build errors out when building image:
    // Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
    // See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#privileged_mode
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.id
    }

    environment_variable {
      name  = "REPOSITORY_URL"
      value = aws_ecr_repository.frontend.repository_url
    }
  }
}
