terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm" # --> by default it's - "registry.terraform.io/hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  /*
  # terraform state storage to Azure storage container
  # will store the state of the bonus b entire infrastructure.
  backend "azurerm" {
    resource_group_name  = "devEnv-rg-bootcamp-tf"
    storage_account_name = "tomerbcstorageaccount"
    container_name       = "bootcamp-storage-container"
    key                  = "week5-bonus-b-terraform.tfstate"
  }
*/
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# local variables/values
locals {
  name_prefix = var.environment
  # priorities/ports for inbound security rules of the public NSG
  public_nsg_inbound_ports_map = {
    /* "1000" : "8080", */
    "1010" : "22"
  }
}
