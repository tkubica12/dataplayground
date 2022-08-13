variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# Data Generators
variable "users_count" {
  type    = number
  default = 1000000
}
  
variable "products_count" {
  type    = number
  default = 100000
}
  
variable "orders_count" {
  type    = number
  default = 10000000
}
  