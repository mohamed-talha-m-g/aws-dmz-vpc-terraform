locals {
  nacl_count = var.enable_nacls ? 1 : 0
}

#------nacl-private-app--------------
resource "aws_network_acl" "app" {
  count = local.nacl_count

  vpc_id     = aws_vpc.DMZ-VPC.id
  subnet_ids = aws_subnet.private-app[*].id

  tags = {
    Name = "${var.project_name}-nacl-private-app"
  }
}
#-----------Inbound: app port from each public subnet (from ALB)------
resource "aws_network_acl_rule" "app_in_from_public" {
  count = var.enable_nacls ? length(var.public_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 100 + (count.index * 10)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = var.app_port
  to_port        = var.app_port
}

#Inbound: ephemeral return traffic (replies from internet via NAT, and from DB)
resource "aws_network_acl_rule" "app_in_ephemeral" {
  count = local.nacl_count

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

#Outbound: HTTPS to internet
resource "aws_network_acl_rule" "app_out_https" {
  count = local.nacl_count

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
#Outbound: HTTP to internet
resource "aws_network_acl_rule" "app_out_http" {
  count = local.nacl_count

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.app_port
  to_port        = var.app_port
}

#Outbound: MySQL to each DB subnet

resource "aws_network_acl_rule" "app_out_mysql" {
  count = var.enable_nacls ? length(var.private_app_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 120 + (count.index * 10)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_db_subnet_cidrs[count.index]
  from_port      = 3306
  to_port        = 3306
}

#Outbound: ephemeral replies back to the ALB in each public subnet
resource "aws_network_acl_rule" "app_out_ephemeral_to_public" {
  count = var.enable_nacls ? length(var.public_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.app[0].id
  rule_number    = 140 + (count.index * 10)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

#----------nacl-private-db-------------

resource "aws_network_acl" "private-db" {
  count = local.nacl_count

  vpc_id     = aws_vpc.DMZ-VPC.id
  subnet_ids = aws_subnet.private-db[*].id

  tags = {
    Name = "${var.project_name}-nacls-private-db"
  }
}

resource "aws_network_acl_rule" "private-db" {
  count = var.enable_nacls ? length(var.private_app_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.private-db[0].id
  rule_number    = 100 + (count.index * 10)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_app_subnet_cidrs[count.index]
  from_port      = 3306
  to_port        = 3306
}

#Outbound: ephemeral replies back to each app subnet -----------
resource "aws_network_acl_rule" "private_db_out_ephemeral" {
  count = var.enable_nacls ? length(var.private_app_subnet_cidrs) : 0

  network_acl_id = aws_network_acl.private-db[0].id
  rule_number    = 100 + (count.index * 10)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_app_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}