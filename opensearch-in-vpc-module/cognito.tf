####################################################################################################
# Cognito User Pool
####################################################################################################
resource "aws_cognito_user_pool" "aos_pool" {
  name = "${var.aos_domain_name}-opensearch"

  username_attributes = [ "email" ]
  auto_verified_attributes = [ "email" ]

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name = "verified_email"
      priority = 1
    }
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_domain" "aos_user_pool_domain" {
  domain = "${var.aos_domain_name}-opensearch-${local.aws_account_id}-${local.aws_region}"
  user_pool_id = aws_cognito_user_pool.aos_pool.id
}

locals {
  cognito_user_pool_domain = "${aws_cognito_user_pool_domain.aos_user_pool_domain.domain}.auth.${local.aws_region}.amazoncognito.com"
}

resource "aws_cognito_user_pool_client" "aos_user_pool_client" {
  name = "${var.aos_domain_name}-opensearch"
  user_pool_id = aws_cognito_user_pool.aos_pool.id

  generate_secret = true

  /*
  supported_identity_providers = ["COGNITO"]

  callback_urls = [
    "https://${data.aws_elasticsearch_domain.aos.kibana_endpoint}app/kibana"
  ]

  logout_urls = [
    "https://${data.aws_elasticsearch_domain.aos.kibana_endpoint}app/kibana"
  ]

  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true
  */

  /*
  The changes to these properties are ignored because they're set through AWS CLI.
  This is needed due to the issue with the AWS Terraform provider, as can be seen in the link below:
  https://github.com/hashicorp/terraform-provider-aws/issues/5557
  */
  lifecycle {
    ignore_changes = [
      supported_identity_providers,
      callback_urls,
      logout_urls,
      allowed_oauth_flows,
      allowed_oauth_scopes,
      allowed_oauth_flows_user_pool_client
    ]
  }
}

resource "null_resource" "set_cognito_identity_providers" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-COMMAND
      app_clients=(`aws cognito-idp list-user-pool-clients --user-pool-id ${aws_cognito_user_pool.aos_pool.id} | jq -r '.UserPoolClients[].ClientId'`)

      providers=''
      for app_client_id in $${app_clients[@]}; do
        providers+=" ProviderName=\"cognito-idp.${local.aws_region}.amazonaws.com/${aws_cognito_user_pool.aos_pool.id}\",ClientId=\"$app_client_id\""
      done

      aws cognito-identity update-identity-pool \
        --identity-pool-id "${aws_cognito_identity_pool.aos_pool.id}" \
        --identity-pool-name "${local.identity_pool_name}" \
        --no-allow-unauthenticated-identities \
        --cognito-identity-providers $providers
    COMMAND
  }

  depends_on = [
    aws_elasticsearch_domain.aos,
    aws_cognito_user_pool_client.aos_user_pool_client,
    aws_cognito_identity_pool.aos_pool
  ]
}

####################################################################################################
# Cognito Identity Pool
####################################################################################################
locals {
  identity_pool_name = replace("${var.aos_domain_name}-opensearch", "-", "_")
}

resource "aws_cognito_identity_pool" "aos_pool" {
  identity_pool_name = local.identity_pool_name
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id = aws_cognito_user_pool_client.aos_user_pool_client.id
    provider_name = aws_cognito_user_pool.aos_pool.endpoint
  }

  tags = var.tags
}

resource "aws_cognito_identity_pool_roles_attachment" "aos_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.aos_pool.id
  roles = {
    "authenticated" = aws_iam_role.aos_cognito_authenticated.arn
    "unauthenticated" = aws_iam_role.aos_cognito_unauthenticated.arn
  }
}

####################################################################################################
# Authenticated Role
####################################################################################################
resource "aws_iam_role" "aos_cognito_authenticated" {
  name = "${var.aos_domain_name}-aos-cognito-authenticated"
  assume_role_policy = data.aws_iam_policy_document.aos_cognito_authenticated_policy_document.json

  tags = var.tags
}

data "aws_iam_policy_document" "aos_cognito_authenticated_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [aws_cognito_identity_pool.aos_pool.id]
    }
    condition {
      test = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values = ["authenticated"]
    }
  }
}

resource "aws_iam_role_policy" "aos_cognito_authenticated" {
  name = "${var.aos_domain_name}-aos-cognito-authenticated"
  role = aws_iam_role.aos_cognito_authenticated.id

  policy = data.aws_iam_policy_document.aos_cognito_authenticated.json
}

data "aws_iam_policy_document" "aos_cognito_authenticated" {
  statement {
    effect = "Allow"
    actions = [
      "mobileanalytics:PutEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-sync:*"
    ]
    resources = [
      "arn:aws:cognito-sync:${local.aws_region}:${local.aws_account_id}:identitypool/${aws_cognito_identity_pool.aos_pool.id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-identity:ListIdentityPools"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-identity:*"
    ]
    resources = [
      "arn:aws:cognito-identity:${local.aws_region}:${local.aws_account_id}:identitypool/${aws_cognito_identity_pool.aos_pool.id}"
    ]
  }
}

####################################################################################################
# Unauthenticated Role
####################################################################################################
resource "aws_iam_role" "aos_cognito_unauthenticated" {
  name = "${var.aos_domain_name}-aos-cognito-unauthenticated"
  assume_role_policy = data.aws_iam_policy_document.aos_cognito_unauthenticated_policy_document.json

  tags = var.tags
}

data "aws_iam_policy_document" "aos_cognito_unauthenticated_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [aws_cognito_identity_pool.aos_pool.id]
    }
    condition {
      test = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values = ["unauthenticated"]
    }
  }
}

resource "aws_iam_role_policy" "aos_cognito_unauthenticated" {
  name = "${var.aos_domain_name}-aos-cognito-unauthenticated"
  role = aws_iam_role.aos_cognito_unauthenticated.id
  policy = data.aws_iam_policy_document.aos_cognito_unauthenticated.json
}

data "aws_iam_policy_document" "aos_cognito_unauthenticated" {
  statement {
    effect = "Allow"
    actions = [
      "mobileanalytics:PutEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-sync:*"
    ]
    resources = [
      "arn:aws:cognito-sync:${local.aws_region}:${local.aws_account_id}:identitypool/${aws_cognito_identity_pool.aos_pool.id}"
    ]
  }
}

####################################################################################################
# Role enabling OpenSearch to access Cognito
####################################################################################################
resource "aws_iam_role" "cognito_for_aos" {
  name = "${var.aos_domain_name}-cognito-for-aos"
  assume_role_policy = data.aws_iam_policy_document.cognito_for_aos_policy_document.json

  tags = var.tags
}

data "aws_iam_policy_document" "cognito_for_aos_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cognito_for_aos" {
  role = aws_iam_role.cognito_for_aos.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonESCognitoAccess"
}
