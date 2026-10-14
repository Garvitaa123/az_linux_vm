variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "prefix" {
  description = "Prefix used for naming all resources"
  type        = string
  default     = "demo"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "web_subnet_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "app_subnet_prefix" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "db_subnet_prefix" {
  type    = list(string)
  default = ["10.0.3.0/24"]
}

# Azure requires the Bastion subnet to be named "AzureBastionSubnet" and be /26 or larger
variable "bastion_subnet_prefix" {
  type    = list(string)
  default = ["10.0.4.0/26"]
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ats_v2"
}

# Zones 1 and 3 are restricted for this subscription in Central India; zone 2 is open.
variable "availability_zone" {
  description = "Availability zone for the VM and its data disk (must match)"
  type        = string
  default     = "2"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "data_disk_size_gb" {
  type    = number
  default = 32
}

variable "allowed_source_cidr" {
  description = "Source allowed to reach the Web VM on ports 80/22. Restrict SSH to your own IP (x.x.x.x/32) in real use."
  type        = string
  default     = "*"
}

variable "app_port" {
  description = "Port the app tier listens on"
  type        = string
  default     = "8080"
}

variable "db_port" {
  description = "Port the DB tier listens on (3306 MySQL, 5432 PostgreSQL, 1433 SQL Server)"
  type        = string
  default     = "3306"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
