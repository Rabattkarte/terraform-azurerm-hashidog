# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

# Outputs file
output "catapp_url" {
  value = "http://${azurerm_public_ip.catapp-pip.fqdn}"
}

output "catapp_url2" {
  value = "http://${data.azurerm_public_ip.example.domain_name_label}"
}

output "catapp_ip" {
  value = "http://${data.azurerm_public_ip.example.ip_address}"
}
