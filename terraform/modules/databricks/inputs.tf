variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_resource_group_name" {
  type = string
}

variable "node_sku" {
  type = string
  default = "Standard_D4s_v5"
}

variable "eventhub_name_pageviews" {
  type = string
}

variable "eventhub_name_stars" {
  type = string
}

variable "eventhub_namespace_name" {
  type = string
}

variable "eventhub_resource_group_name" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "keyvault_id" {
  type = string
}

variable "existing_metastore_id" {
  type = string
  default = ""
}
