data "aws_ami" "proxy" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name = "description"
    values = ["Amazon Linux 2 *"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "state"
    values = ["available"]
  }
}

resource "aws_instance" "proxy" {
  ami = data.aws_ami.proxy.id
  instance_type = "t3.micro"

  subnet_id = var.proxy_subnet_id
  vpc_security_group_ids = [aws_security_group.proxy.id]

  user_data = templatefile("${path.module}/proxy_instance_init_script.sh", {
    self_signed_certificate_subject = var.self_signed_certificate_subject
    vpc_dns_resolver_ip = cidrhost(data.aws_vpc.selected.cidr_block, 2)
    elasticsearch_endpoint = aws_elasticsearch_domain.aos.endpoint
    cognito_host = local.cognito_user_pool_domain
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required" # IMDSv2
  }

  tags = merge(var.tags, {
    Name = "${var.aos_domain_name}-opensearch-proxy"
  })
}

resource "aws_eip" "proxy" {
  instance = aws_instance.proxy.id
  vpc = true

  tags = merge(var.tags, {
    Name = "${var.aos_domain_name}-opensearch-proxy"
  })
}
