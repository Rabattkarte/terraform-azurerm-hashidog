# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
}

variable "environment" {
  description = "The environment of this deployment."
  default     = "Production"
}

variable "location" {
  description = "The region where the virtual network is created."
  default     = "centralus"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_B1s"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "0001-com-ubuntu-server-jammy"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "22_04-lts"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name for linux and mysql"
  default     = "hashicorp"
}

variable "admin_password" {
  description = "Administrator password for linux and mysql"
  default     = "Password123!"
}
