

# Azure Location
variable "location" {
  type = string
  description = "Azure Region where all these resources will be provisioned"
  default = "centralindia"
}

# Azure Resource Group Name
variable "resource_group_name" {
  type = string
  description = "This variable defines the Resource Group"
  default = "terraform-aks"
}

# Azure AKS Environment Name
variable "environment" {
  type = string  
  description = "This variable defines the Environment "  
  
}


# AKS Input Variables

# SSH Public Key for Linux VMs
variable "ssh_public_key" {
  description = "This variable defines the SSH Public Key for Linux k8s Worker nodes"  
}



