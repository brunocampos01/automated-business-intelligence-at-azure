# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
    name                          = "${var.product_client_name}-rg"
    location                      = var.location
    tags                          = var.tags
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
    name                          = "${var.product_client_name_lower}-logaw"
    location                      = var.location
    resource_group_name           = azurerm_resource_group.rg.name
    sku                           = "PerGB2018"
    retention_in_days             = 30
    tags                          = var.tags
}
