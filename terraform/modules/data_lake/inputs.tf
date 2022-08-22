variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "keyvault_id" {
  type = string
}

# Data Generators
variable "users_count" {
  type    = number
  default = 1000000
}
  
variable "vip_users_count" {
  type    = number
  default = 10000
}
  
variable "products_count" {
  type    = number
  default = 100000
}
  
variable "orders_count" {
  type    = number
  default = 10000000
}
  