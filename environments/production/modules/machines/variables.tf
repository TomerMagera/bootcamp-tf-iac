variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

# These variables' values will be passed from the root module
variable "location" {
  type = string
}
/* 
variable "avset_id" {
  type = string
} */

variable "resource_group_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

# remove below line later to try with the ip provided via the LB
variable "public_ip" {
  type    = string
  default = ""
}

# This will be my default, and if other will be 
# needed, we can pass the value from the root module.
variable "vm_size" {
  default = "Standard_B1s"
}

# tags to be used for resources
variable "tags" {
  type = map(string)
  default = {
    Environment = "Terraform in the Bootcamp!!"
    Owner       = "Tomer Magera"
  }
}