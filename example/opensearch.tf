module "opensearch_example" {
  source = "../opensearch-in-vpc-module"

  aos_domain_name = "my-example"

  aos_data_instance_count = 1
  aos_data_instance_type = "t3.small.elasticsearch"
  aos_data_instance_storage = 50
  aos_master_instance_count = 0
  aos_master_instance_type = "t3.small.elasticsearch"

  aos_domain_subnet_ids = [aws_subnet.opensearch_domain.id]

  vpc_id = aws_vpc.opensearch_example.id
  proxy_subnet_id = aws_subnet.opensearch_proxy.id
  proxy_inbound_cidr_blocks = ["0.0.0.0/0"] # WARNING: Restrict the IP range!

  tags = {
    Project = var.project_name
  }
}
