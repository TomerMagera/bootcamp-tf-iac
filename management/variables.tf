#################################
# General variables
#################################

# the type of envirment dev/test/staging/preprod/prod
variable "environment" {
  description = "the type of envirment dev/test/staging/preprod/prod"
  type        = string
  default     = "devEnv"
}

# resource group name
variable "resource_group_name" {
  description = "resource group name"
  type        = string
  default     = "rg"
}

variable "staging_rg_name" {
  description = "resource group name of the staging env"
  type        = string
}

variable "production_rg_name" {
  description = "resource group name of the production env"
  type        = string
}

variable "staging_vnet" {
  description = "vnet name of the staging env"
  type        = string
}

variable "production_vnet" {
  description = "vnet name of the production env"
  type        = string
}

variable "peering_name_staging" {
  description = "peering name to the staging env"
  type        = string
}

variable "peering_name_production" {
  description = "peering name to the production env"
  type        = string
}

# resource group region location
variable "resource_group_location" {
  description = "resource group region location"
  type        = string
  default     = "westeurope"
}

# tags to be used for resources
variable "tags" {
  type = map(string)
  default = {
    Environment = "Terraform in the Bootcamp!!"
    Owner       = "Tomer Magera"
  }
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

# This will be my default, and if other will be 
# needed, we can pass the value from the root module.
variable "vm_size" {
  default = "Standard_B1s"
}

variable "controller_public_ipname" {
  description = "name of the public ip of the controller"
  type        = string
  default     = "controllerpubip"
}
#################################
# Network related variables
#################################

# name of the virtual network
variable "vnet_name" {
  description = "the name of the virtual network"
  type        = string
  default     = "vnet"
}

# virtual network address space
variable "vnet_address_space" {
  description = "virtual network address space"
  type        = list(string)
}

# names of the subnets
variable "subnets_names" {
  description = "names of the subnets"
  type        = list(string)
  default     = ["my-subnet"]
}

# CIDR of each subnet
variable "subnets_cidrs" {
  description = "list of CIDR of each subnet"
  type        = list(string)
}

# names of the NSGs
variable "nsgs" {
  description = "names of the NSGs"
  type        = list(string)
  default     = ["public-nsg"]
}
