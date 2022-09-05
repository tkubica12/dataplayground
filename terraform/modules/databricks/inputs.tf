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

