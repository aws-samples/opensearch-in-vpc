resource "aws_vpc" "opensearch_example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "opensearch-example"
    Project = var.project_name
  }
}

resource "aws_subnet" "opensearch_domain" {
  vpc_id = aws_vpc.opensearch_example.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${local.aws_region}${var.availability_zone}"

  tags = {
    Name = "opensearch-example-domain"
    Project = var.project_name
  }
}

resource "aws_subnet" "opensearch_proxy" {
  vpc_id = aws_vpc.opensearch_example.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${local.aws_region}${var.availability_zone}"

  tags = {
    Name = "opensearch-example-proxy"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "opensearch_proxy" {
  vpc_id = aws_vpc.opensearch_example.id

  tags = {
    Name = "opensearch-example-proxy"
    Project = var.project_name
  }
}

resource "aws_route_table" "opensearch_proxy" {
  vpc_id = aws_vpc.opensearch_example.id

  tags = {
    Name = "opensearch-example-proxy"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "opensearch_proxy" {
  subnet_id = aws_subnet.opensearch_proxy.id
  route_table_id = aws_route_table.opensearch_proxy.id
}

resource "aws_route" "opensearch_proxy_igw" {
  route_table_id = aws_route_table.opensearch_proxy.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.opensearch_proxy.id
}
