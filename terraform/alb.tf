resource "aws_security_group" "alb" {
  name   = var.alb-sg
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    protocol    = "TCP"
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "TCP"
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "suitme-alb-security-group"
  }
}

resource "aws_lb" "alb" {
  name               = var.alb
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }
}
