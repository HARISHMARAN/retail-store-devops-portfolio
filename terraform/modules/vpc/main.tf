data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, 3)

  max_azs = length(local.azs)

  vpc_id = aws_vpc.this[0].id

  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? local.max_azs : local.max_azs

  # Use `var.tags` by default, merge with other specific tags
  tags = merge(
    var.tags,
    {
      Terraform   = "true"
      Environment = var.name
    }
  )
}

resource "aws_vpc" "this" {
  count = 1

  cidr_block           = var.cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    local.tags,
    var.vpc_tags,
    {
      Name = var.name
    }
  )
}

resource "aws_internet_gateway" "this" {
  count = 1

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.igw_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets) > 0 ? local.max_azs : 0

  vpc_id                  = local.vpc_id
  cidr_block              = element(distinct(var.public_subnets), count.index)
  availability_zone       = element(local.azs, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    var.public_subnet_tags,
    {
      Name                                           = "${var.name}-public-${element(local.azs, count.index)}"
      "kubernetes.io/role/elb"                       = "1"
      "kubernetes.io/cluster/${var.name}"             = "shared"
      "kubernetes.io/role/internal-elb"               = "1"
    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets) > 0 ? local.max_azs : 0

  vpc_id            = local.vpc_id
  cidr_block        = element(distinct(var.private_subnets), count.index)
  availability_zone = element(local.azs, count.index)

  tags = merge(
    local.tags,
    var.private_subnet_tags,
    {
      Name                                           = "${var.name}-private-${element(local.azs, count.index)}"
      "kubernetes.io/role/internal-elb"               = "1"
      "kubernetes.io/cluster/${var.name}"             = "shared"
    }
  )
}

resource "aws_subnet" "database" {
  count = length(var.database_subnets) > 0 ? local.max_azs : 0

  vpc_id            = local.vpc_id
  cidr_block        = element(distinct(var.database_subnets), count.index)
  availability_zone = element(local.azs, count.index)

  tags = merge(
    local.tags,
    var.database_subnet_tags,
    {
      Name = "${var.name}-database-${element(local.azs, count.index)}"
    }
  )
}

resource "aws_db_subnet_group" "database" {
  count = length(aws_subnet.database) > 0 ? 1 : 0

  name        = "${var.name}-database"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-database-subnet-group"
    }
  )
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    local.tags,
    var.nat_gateway_tags,
    {
      Name = "${var.name}-nat-eip-${count.index + 1}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway && !var.az_reuse_nat_gateway_ips ? local.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    local.tags,
    var.nat_gateway_tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "az_reuse" {
  count = var.enable_nat_gateway && var.az_reuse_nat_gateway_ips ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = element(aws_subnet.public[*].id, 0)

  tags = merge(
    local.tags,
    var.nat_gateway_tags,
    {
      Name = "${var.name}-nat-shared"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  count = length(aws_subnet.public) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.public_route_table_tags,
    {
      Name = "${var.name}-public"
    }
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(aws_route_table.public) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count = local.max_azs

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.private_route_table_tags,
    {
      Name = "${var.name}-private-${element(local.azs, count.index)}"
    }
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway && !var.single_nat_gateway && !var.az_reuse_nat_gateway_ips ? local.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route" "private_nat_gateway_single" {
  count = var.enable_nat_gateway && var.single_nat_gateway && !var.az_reuse_nat_gateway_ips ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route" "private_nat_gateway_az_reuse" {
  count = var.enable_nat_gateway && var.az_reuse_nat_gateway_ips ? local.max_azs : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.az_reuse[0].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "database" {
  count = length(aws_subnet.database) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    local.tags,
    var.database_route_table_tags,
    {
      Name = "${var.name}-database"
    }
  )
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id            = local.vpc_id
  availability_zone = var.vpn_gateway_az

  tags = merge(
    local.tags,
    {
      Name = "${var.name}-vgw"
    }
  )
}

resource "aws_dx_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  name            = "${var.name}-dxgw"
  amazon_side_asn = "64512"
}

resource "aws_dx_gateway_vpc_attachment" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id                = local.vpc_id
  dx_gateway_id         = aws_dx_gateway.this[0].id
  vpn_gateway_id        = aws_vpn_gateway.this[0].id
  associated_gateway_id = aws_vpn_gateway.this[0].id
}


