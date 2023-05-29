# CREATING SECURITY GROUP FOR THE INSTNCES (OPEN SSH PORT)
resource "aws_security_group" "security_group" {
  name        = "SSH-HTTP Communication"
  description = "Allow inbound traffic to the Jenkins server"

  dynamic "ingress" {
    for_each = var.security_group
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port2
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name                = "my_sec_grp"
    LaunchedByTerraform = "True"
  }
}

# CREATING SECURITY GROUP FOR THE LOAD BALANCER (OPEN HTTP PORT)
resource "aws_security_group" "security_group_lb" {
  name        = "My-demo-sg_lb"
  description = "Allow http traffic to the lb"

  dynamic "ingress" {
    for_each = var.security_group_lb
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port2
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name                = "my_sec_grp_for_lb"
    LaunchedByTerraform = "True"
  }
}

# ADDING AN INBOUND RULE TO OUR INSTANCES SEC GROUP (LISTEN ON THE LB SEC GROUP)
resource "aws_security_group_rule" "allow_lb_ingress" {
  description              = "Allow inbound traffic from Security Group 2"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.security_group_lb.id
  security_group_id        = aws_security_group.security_group.id
}

# CREATING A KEY PAIR TO ACCES OUR INSTANCES
resource "aws_key_pair" "my_key_pair" {
  depends_on = [aws_security_group.security_group]
  key_name   = "Linux_keyPair"
  public_key = file("${path.module}/mykeypair")

}

# CREATING OUR INSTANCES
resource "aws_instance" "http_server" {
  depends_on    = [aws_key_pair.my_key_pair]
  ami           = data.aws_ami.http_server.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  count         = 4
  tags = {
    "Name" = "http_server-${count.index}"
  }
  availability_zone = count.index == 0 || count.index == 2 ? "us-east-1e" : "us-east-1b"
  security_groups   = [aws_security_group.security_group.name]
  user_data         = count.index == 0 || count.index == 1 ? file("${path.module}/user_data.sh") : file("${path.module}/user_data_2.sh")
}

# CREATING THE LOAD BALANCER
resource "aws_lb" "my_lb" {
  name               = "my-alb"
  load_balancer_type = "application"
  subnets            = flatten([for instance in aws_instance.http_server : instance.subnet_id])
  security_groups    = [aws_security_group.security_group_lb.id]

  tags = {
    Name = "My ALB"
  }
}

# CREATING 2 TARGETS GROUPS
resource "aws_lb_target_group" "my_target_group" {
  count    = 2
  name     = "demo-tg-alb-${count.index}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.my_vpc.id
}

# ADDING THE 2 FIRST SERVER TO THE TARGET GROUP 1
resource "aws_lb_target_group_attachment" "register_target" {
  count            = 2
  target_group_arn = aws_lb_target_group.my_target_group[0].arn
  target_id        = aws_instance.http_server[count.index].id
  port             = 80
}

# ADDING THE 2 LAST SERVER TO THE TARGET GROUP 2
resource "aws_lb_target_group_attachment" "register_target_2" {
  count            = 2
  target_group_arn = aws_lb_target_group.my_target_group[1].arn
  target_id        = aws_instance.http_server[count.index + 2].id
  port             = 80
}

# CREATING THE DEFAULT LLISTENER
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "This is a fixed response."
      status_code  = "404"
    }
  }
}

# CONFIGURING OTHER RULES IN THE LISTENER
resource "aws_lb_listener_rule" "target_1" {
  listener_arn = aws_lb_listener.listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group[0].arn
  }

  condition {
    path_pattern {
      values = ["/target1/index.html"]
    }
  }
}

resource "aws_lb_listener_rule" "target_2" {
  listener_arn = aws_lb_listener.listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group[1].arn
  }

  condition {
    path_pattern {
      values = ["/target2/index.html"]
    }
  }
}