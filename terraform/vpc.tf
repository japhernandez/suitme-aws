resource "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "suitme-app-vpc"
  }
}

## Subnets
resource "aws_subnet" "public" {
  count                   = length(local.public_subnets)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "suitme-app-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "apps" {
  count             = length(local.app_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.app_subnets[count.index]

  tags = {
    Name = "suitme-app-subnet-${count.index}"
  }
}

## Gateways
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "suitme-app-gateway"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_eip" "nat" {
  vpc = true
}

## Table Route
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "suitme-app-route-table-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "suitme-app-route-table-private"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app" {
  count          = length(local.app_subnets)
  subnet_id      = aws_subnet.apps[count.index].id
  route_table_id = aws_route_table.private.id
}
