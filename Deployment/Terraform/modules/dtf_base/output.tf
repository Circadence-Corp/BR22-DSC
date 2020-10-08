output "public_ips" {
    value = {for i in data.azurerm_public_ip.all_public_ips : i.name =>i.ip_address}
}