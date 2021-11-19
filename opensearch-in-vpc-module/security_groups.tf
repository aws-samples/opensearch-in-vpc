data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet" "opensearch" {
  count = length(var.aos_domain_subnet_ids)

  id = var.aos_domain_subnet_ids[count.index]
}

resource "aws_security_group" "opensearch" {
  name = "${var.aos_domain_name}-opensearch-domain"
  description = "OpenSearch Domain"
  vpc_id = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "opensearch" {
  count = length(var.aos_domain_subnet_ids)

  description = "Cluster Subnets"
  security_group_id = aws_security_group.opensearch.id

  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = data.aws_subnet.opensearch[count.index].cidr_block == null ? [] : [data.aws_subnet.opensearch[count.index].cidr_block]
  ipv6_cidr_blocks = data.aws_subnet.opensearch[count.index].ipv6_cidr_block == null ? [] : [data.aws_subnet.opensearch[count.index].ipv6_cidr_block]
}

resource "aws_security_group_rule" "elasticsearch_proxy" {
  description = "Proxy"
  security_group_id = aws_security_group.opensearch.id

  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = aws_security_group.proxy.id
}

resource "aws_security_group" "proxy" {
  name = "${var.aos_domain_name}-opensearch-proxy"
  description = "Proxy for OpenSearch Domain"
  vpc_id = var.vpc_id

  ingress {
    description = "TLS from IP range"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = var.proxy_inbound_cidr_blocks
    ipv6_cidr_blocks = var.proxy_inbound_ipv6_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}
