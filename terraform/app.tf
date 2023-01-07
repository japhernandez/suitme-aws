resource "aws_ecr_repository" "app" {
  name = var.repository
}

resource "aws_security_group" "app_task" {
  name = var.task_security_group
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 9000
    protocol  = "TCP"
    to_port   = 9000
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    protocol  = "TCP"
    to_port   = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "suitme-task-security-group"
  }
}


