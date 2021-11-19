####################################################################################################
# Elasticsearch
####################################################################################################
output "opensearch_domain_arn" {
  value = aws_elasticsearch_domain.aos.arn
}

output "opensearch_domain_id" {
  value = aws_elasticsearch_domain.aos.domain_id
}

output "opensearch_domain_name" {
  value = aws_elasticsearch_domain.aos.domain_name
}

output "opensearch_domain_endpoint" {
  value = aws_elasticsearch_domain.aos.endpoint
}

output "opensearch_domain_kibana_endpoint" {
  value = aws_elasticsearch_domain.aos.kibana_endpoint
}

output "opensearch_security_group_id" {
  value = aws_security_group.opensearch.id
}

####################################################################################################
# Cognito
####################################################################################################
output "cognito_authenticated_iam_role_arn" {
  value = aws_iam_role.aos_cognito_authenticated.arn
}

output "cognito_unauthenticated_iam_role_arn" {
  value = aws_iam_role.aos_cognito_unauthenticated.arn
}

output "cognito_user_pool_domain" {
  value = local.cognito_user_pool_domain
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.aos_pool.id
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.aos_pool.id
}

output "cognito_identity_pool_name" {
  value = local.identity_pool_name
}

####################################################################################################
# Proxy
####################################################################################################
output "proxy_dns" {
  value = aws_eip.proxy.public_dns
}

output "proxy_ip" {
  value = aws_eip.proxy.public_ip
}

output "proxy_security_group_id" {
  value = aws_security_group.proxy.id
}
