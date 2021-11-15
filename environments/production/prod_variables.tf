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

#the quantity of webservers to create
variable "num_webservers_to_create" {
  description = "the quantity of webservers to create"
  type        = number
  default     = "1"
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "db_admin_user" {
  type = string
}

variable "db_admin_pass" {
  type = string
}

variable "pg_vm_name" {
  description = "name of the vm of the postgres service"
  default     = "pg-vm"
}

# This will be my default, and if other will be 
# needed, we can pass the value from the root module.
variable "vm_size" {
  default = "Standard_B1s"
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

###################################
# Load Balancer related variables
###################################

variable "public_ip_name" {
  type = string
}

# load balancer name
variable "lb_name" {
  type = string
}

variable "publicIp_forLB" {
  type = string
}
