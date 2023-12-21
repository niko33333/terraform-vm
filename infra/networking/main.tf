locals {
  projectName = var.project_name
  environment = var.env
  prefix      = "${local.projectName}-${local.environment}"
  common_tags = {
      projectName = local.projectName
      environment = local.environment
  }
}
# select the az on the region
data "aws_availability_zones" "available" {
}

resource "aws_subnet" "natted" {
  count             = var.number_of_subnet
  cidr_block        = format("%s", element(["10.100.6.0/24", "10.100.7.0/24", "10.100.8.0/24"], count.index))
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = format("${local.prefix}-natted-%s", element(["a", "b", "c"], count.index))
    }
  )
}

resource "aws_subnet" "public" {
  count                   = var.number_of_subnet
  cidr_block              = format("%s", element(["10.100.0.0/24", "10.100.1.0/24", "10.100.2.0/24"], count.index))
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = var.vpc_id
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = format("${local.prefix}-public-%s", element(["a", "b", "c"], count.index))
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.prefix}-igw"
  }

}

resource "aws_eip" "ngw" {
  count      = var.number_of_nat
  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    local.common_tags,
    {
      Name = format("${local.prefix}-eip-%s", element(["a", "b"], count.index))
    }
  )
}

resource "aws_nat_gateway" "ngw" {
  count         = var.number_of_nat
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.ngw.*.id, count.index)

  tags = merge(
    local.common_tags,
    {
      Name = format("${local.prefix}-nat-%s", element(["a", "b"], count.index))
    }
  )
}

resource "aws_route_table" "natted" {
  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-rt-natted"
    }
  )
}

resource "aws_route" "nat_direction" {
  count                  = var.number_of_nat
  route_table_id         = aws_route_table.natted.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_nat_gateway.ngw.*.id, count.index)
}

resource "aws_route_table_association" "natted" {
  count          = var.number_of_subnet
  subnet_id      = element(aws_subnet.natted.*.id, count.index)
  route_table_id = aws_route_table.natted.id
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-rt-public"
    }
  )
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = var.number_of_subnet
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
