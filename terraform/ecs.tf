resource "aws_ecs_cluster" "cluster" {
  name = var.cluster
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  execution_role_arn       = aws_iam_role.app_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  container_definitions = templatefile("${abspath(path.root)}/../taskdef.json", {
    IMAGE_PATH = aws_ecr_repository.app.repository_url
  })
}

resource "aws_alb_target_group" "app" {
  name        = var.app_target_group
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

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_ecs_service" "app" {
  name                               = var.app
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.app.arn
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 50
  desired_count                      = 2

  network_configuration {
    subnets         = aws_subnet.apps[*].id
    security_groups = [aws_security_group.app_task.id]
  }

  load_balancer {
    container_name   = var.app
    container_port   = 9000
    target_group_arn = aws_alb_target_group.app.arn
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb.alb]
}
