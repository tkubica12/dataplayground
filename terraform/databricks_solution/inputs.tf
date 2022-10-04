variable "location" {
  type    = string
  default = "westeurope"
}

variable "enable_data_factory" {
  type    = string
  default = true
}

variable "existing_metastore_id" {
  type = string
  default = ""
}