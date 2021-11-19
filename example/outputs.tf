output "opensearch_domain_endpoint" {
  value = module.opensearch_example.opensearch_domain_endpoint
}

output "opensearch_ui" {
  value = "https://${module.opensearch_example.proxy_ip}"
}
