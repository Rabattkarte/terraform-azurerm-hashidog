# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: Apache-2.0

# Outputs file
output "dogapp_url" {
  value = "http://${azurerm_public_ip.dogapp_pip.fqdn}"
}

output "dogapp_ip" {
  value = "http://${data.azurerm_public_ip.dogapp_pip.ip_address}"
}
