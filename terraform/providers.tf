terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state would live in an Azure Storage account, with state locking
  # provided by the blob lease. Commented out so `terraform validate` runs
  # without credentials; see the README for the production setup.
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "sthmctsdevteststate"
  #   container_name       = "tfstate"
  #   key                  = "dev-test-backend.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

provider "random" {}
