variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group for temporary storage"
  type        = string
  default     = "rg-de-homework-temp"
}

variable "storage_account_prefix" {
  description = "Lowercase prefix for storage account name"
  type        = string
  default     = "dehw"
}

variable "container_name" {
  description = "Storage container name"
  type        = string
  default     = "pipeline-data"
}
