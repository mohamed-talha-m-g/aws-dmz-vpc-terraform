resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "ALB: inblund 80/433 from internet"
  vpc_id      = aws_vpc.DMZ-VPC.id

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow port HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbondtraffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg-app"
  description = "App tier: inbound app port from ALB only"
  vpc_id      = aws_vpc.DMZ-VPC.id

  tags = {
    Name = "${var.project_name}-sg-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow traffic only from alb"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_from_alb" {
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbond traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-sg-db"
  description = "DB tier: inbound 3306 from app tier only"
  vpc_id      = aws_vpc.DMZ-VPC.id

  tags = {
    Name = "${var.project_name}-sg-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL from app tier"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.db.id
  description       = "Allow all out bond traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}