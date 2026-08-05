variable "project" {
  type        = string
  description = "Short project slug used as a prefix for resource names."
  default     = "hmctsdevtest"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.project))
    error_message = "project must be 2-12 lowercase alphanumeric characters and start with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment; kept short so it fits Azure name limits."
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, staging, prod."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "uksouth"
}

variable "resource_group_name" {
  type        = string
  description = "Override for the resource group name. Defaults to <project>-<environment>-rg."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged over the common tags applied to every resource."
  default     = {}
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL Flexible Server major version."
  default     = "16"
}

variable "postgres_sku_name" {
  type        = string
  description = "SKU for the PostgreSQL Flexible Server (tier + size)."
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type        = number
  description = "Storage allocated to the PostgreSQL Flexible Server, in MB."
  default     = 32768

  validation {
    condition     = var.postgres_storage_mb >= 32768
    error_message = "postgres_storage_mb must be at least 32768 (32 GB), the Flexible Server minimum."
  }
}

variable "postgres_admin_username" {
  type        = string
  description = "Administrator login for the PostgreSQL server."
  default     = "psqladmin"
}

variable "database_name" {
  type        = string
  description = "Name of the application database created on the server."
  default     = "dev_test"
}

variable "container_image" {
  type        = string
  description = "Fully qualified image reference the Container App runs (e.g. registry/test-backend:<sha>)."
}

variable "container_cpu" {
  type        = number
  description = "vCPU allocated to the app container. Must pair with a valid Container Apps memory value."
  default     = 0.5
}

variable "container_memory" {
  type        = string
  description = "Memory allocated to the app container (e.g. 1Gi). Must pair with the chosen CPU value."
  default     = "1Gi"
}

variable "app_port" {
  type        = number
  description = "Port the application listens on inside the container."
  default     = 4000
}
