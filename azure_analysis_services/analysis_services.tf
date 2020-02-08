# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
    name                        = "${var.product_client_name}-rg"
    location                    = var.location
    tags                        = var.tags
}


resource "azurerm_analysis_services_server" "analysis_services_server" {
    name                        = "${var.product_name}${var.client_name_lower}"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    sku                         = "S0"
    admin_users                 = var.list_admins_global
    backup_blob_container_uri   = "https://${var.product_name}${var.client_name}.blob.core.windows.net/analysis-services-container/${var.sas_token}"
    tags                        = var.tags
    querypool_connection_mode   = "All"
    enable_power_bi_service     = true
    ipv4_firewall_rule {
        name                    = "all"
        range_start             = "10.10.10.10"
        range_end               = "255.255.255.255"
      }
}
