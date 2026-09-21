# vuln-code-snippet start iacLeakedKeyChallenge
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-${count.index}"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb" "juice_shop" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "juice_shop" {
  name        = "${var.project_name}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/rest/admin/application-version"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.juice_shop.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.juice_shop.arn
  }
}

resource "aws_iam_server_certificate" "juice_shop_tls" {
  name             = "${var.project_name}-tls-cert"
  certificate_body = file("${path.module}/certs/server.crt")
  private_key      = "-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEAxK6vfow5SzaWsjrlA3tSO1jLcs6y//6oDEq+YTrAEXSlWuF2\n3WB+jleF4azK0zVWLTrUyPejOMm8FkqClJjg7mio/GpjUB1yAwGf83kpvKh1b4JJ\no777uKT7xkezGN8sDu5xpjeGMChV6XjFfPGGrBEh7WjIg15f9NHBqjUbHym0JCcT\n1dkYQ1dKxKmp50aZ7wwMieLYxCVP/YPjU42L9HFmo4QLkWtamTqG9wpQfvZUvq/Y\nrCxXQHBpftMoF37DUKZQ25BfJiCpy2cHpeT/XQzrWiBTOWDOEF4wh1Y7S7bQ+Z1c\nGfHtE3keF+GRpZjIcLUbIiBRyh3CFg1+SxEgewIDAQABAoIBAFWt+YJpyI201poG\n4PwOzWhQCrTVSZIOWBuetee6RbB0/ZGlFXhj0E3m38pLUUIIAqYKcmanxkF3VEnr\npI3iOV5yVmc7W08rvJ6Fpy3T0vQ9+IaencDI8nRh3tJmKqWDlvhcNEMh/gFdmOtv\nsqx2tOGhRwPauTrNMoT+mVyx7MI6T0UM+9vfZZtHawBV0xWkI6EAn+F1w23oM32C\n1H+FrmuUOCbUZXtagax2+RfcM2MuaWJBw2Ps/+8GW5d4UPew5+MIybqDeBTd0GbR\nJRjTYES8I9G/XMo3z7FnlMFdgSvWQ9x5vu7uk8EA1RkMm7RnNQxNahVoes9Wjh77\nJQ/5ldUCgYEA7lqUL5RxRsC5oV4dMaN8TsWrCJ0YfM6W0WGU2v9t28ms//moVfds\nhgMktfbjsijWbTnLUy2izPEjdTryjEqvfr+7aDK8cww+gQAF/NmRy0lTLAO7wj+x\nY8aFbp3XTuxOwI41FmduBDUX5XpBg9fPf4BCOfip7iRUK1GYnto1kQUCgYEA0z5T\nJr8Hfeo1xNdpdG+uW/2/kniBs5mYeJzj6wIbSTKxUmlPSQPM3eBPzyeoA0us71Yz\nZtyZ0QEjXoPpJCHoD4FOAQPrrLhdc5qd40JKAKfNDp6B4hkWGakqrEjSBOO6E/Rw\nMNoqrtorRoZATaOUd0eu8x/M0a6NxW9qrnsIo38CgYBXpJLMlAa6/27CeTq+3+B7\njo9/UVSJv+URBJKZnEanBJdKYGCXi60p8cnz5t5+yilebFvpL+Sm+xwQpSY+k8/I\nCXQ9sjo9C4mIIZwSB2Zmm4Wrr4vAt27gw0SZEgzzhkzG3QOEQ2/euC8bQEMK2bYA\nqgawDlFdsZoJe61k69O6iQKBgB9E2YAhxNUhpyXlEQoYQgIB9KqUxfY05TntV1uB\nK1LReygMyJyxQFETlBzA7QDX4dhntSIjw20JsxeZhRhBIJ2y8T37O5aMj+C94WMz\ne8rPC+5/DhDOz9Oqk9N+z//DSdcMVtMUaD8Lsl41Hy2e6ioh5Ua9zU64fOndzTfY\npHW3AoGATp+Td7yeLePkekH8umhUfOeU4mF9mHO4Ewl58gyU30GOUhftEu7Ai/PX\nH2VhtdYv20xRoYFESbFM4J0CpaGJS2iaM/63mXi6xIT/nHWiO/Y6LsOy/0nepxct\nbTVBTb51ZcjUp1bIu/cIwoXWd0Vw0xf1bybzZcwYtjcfNYWs2Ns=\n-----END RSA PRIVATE KEY-----" # vuln-code-snippet vuln-line iacLeakedKeyChallenge

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.juice_shop.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_iam_server_certificate.juice_shop_tls.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.juice_shop.arn
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_efs_file_system" "juice_shop_data" {
  creation_token = "${var.project_name}-sqlite-data"
  encrypted      = var.efs_encrypted

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name        = "${var.project_name}-sqlite-data"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_efs_mount_target" "juice_shop_data" {
  count           = length(var.public_subnet_cidrs)
  file_system_id  = aws_efs_file_system.juice_shop_data.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "juice_shop_data" {
  file_system_id = aws_efs_file_system.juice_shop_data.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/data"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "${var.project_name}-data-ap"
    Project     = var.project_name
    Environment = var.environment
  }
}
# vuln-code-snippet end iacLeakedKeyChallenge
