####################################################################################################
# General
####################################################################################################
variable "tags" {
  type = map
  default = {}
}

####################################################################################################
# Elasticsearch
####################################################################################################
variable "aos_domain_name" {
  type = string
  description = "Name for Elasticsearch domain, also used as prefix for related resources."
}

variable "opensearch_version" {
  type = string
  default = "7.10"
}

variable "aos_data_instance_count" {
  type = number
  /*
  validation {
    condition = var.aos_data_instance_count > 0
    error_message = "Value must be greater than zero."
  }
  */
}

variable "aos_data_instance_type" {
  type = string
}

variable "aos_data_instance_storage" {
  type = number
}

variable "aos_master_instance_count" {
  type = number
}

variable "aos_master_instance_type" {
  type = string
}

variable "aos_encrypt_at_rest" {
  type = bool
  default = true
  description = "Default is 'true'. Can be disabled for unsupported instance types."
}

variable "aos_zone_awareness_enabled" {
  type = bool
  default = false
}

variable "aos_domain_subnet_ids" {
  type = list(string)
}

####################################################################################################
# VPC
####################################################################################################
variable "vpc_id" {
  type = string
}

variable "proxy_inbound_cidr_blocks" {
  type = list
}

variable "proxy_inbound_ipv6_cidr_blocks" {
  type = list
  default = []
}

####################################################################################################
# Proxy
####################################################################################################
variable "proxy_subnet_id" {
  type = string
}

variable "self_signed_certificate_subject" {
  type = string
  default = "/C=DE"
}
