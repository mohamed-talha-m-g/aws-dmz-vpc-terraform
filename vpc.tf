resource "aws_vpc" "DMZ-VPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#---------Subnet-------------

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.DMZ-VPC.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private-app" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.DMZ-VPC.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-app-${var.availability_zones[count.index]}"
    Tier = "Private-app"
  }
}

resource "aws_subnet" "private-db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.DMZ-VPC.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-db-${var.availability_zones[count.index]}"
    Tier = "private-db"
  }
}

#-------------Internet Gateway -----------------

resource "aws_internet_gateway" "public-igw" {
  vpc_id = aws_vpc.DMZ-VPC.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#-------------Elastic IP for both AZs -------------

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.availability_zones[count.index]}"
  }
  depends_on = [aws_internet_gateway.public-igw]
}

#----------------NAT Gateway for both AZs-----------------

resource "aws_nat_gateway" "private-ngw" {
  count = length(var.availability_zones)

  allocation_id     = aws_eip.nat[count.index].id
  subnet_id         = aws_subnet.public[count.index].id
  connectivity_type = "public"

  tags = {
    Name = "${var.project_name}-nat-${var.availability_zones[count.index]}"
  }
  depends_on = [aws_internet_gateway.public-igw]

}

#----------route table & associate subnets---------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.DMZ-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public-igw.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private-app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.DMZ-VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.private-ngw[count.index].id
  }

  tags = { Name = "${var.project_name}-private-app-rt-${var.availability_zones[count.index]}" }
}

resource "aws_route_table_association" "private-app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private-app[count.index].id
  route_table_id = aws_route_table.private-app[count.index].id

}

resource "aws_route_table" "private-db" {
  vpc_id = aws_vpc.DMZ-VPC.id

  tags = {
    Name = "${var.project_name}-private-db-rt"
  }
}

resource "aws_route_table_association" "private-db" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private-db[count.index].id
  route_table_id = aws_route_table.private-db.id

}

