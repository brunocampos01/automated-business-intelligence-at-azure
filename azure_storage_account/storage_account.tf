# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
    name                        = "${var.product_client_name}-rg"
    location                    = var.location
    tags                        = var.tags
}

resource "azurerm_storage_account" "storage_account" {
    name                        = "${var.product_name}${var.client_name_lower}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = var.location
    account_replication_type    = "RAGRS"
    account_tier                = "Standard"
    access_tier                 = "Cool"
    account_kind                = "BlobStorage"
}

#******************************************************************************
# Container
#******************************************************************************
resource "azurerm_storage_container" "container_analysis_services" {
    name                        = "analysis-services-container"
    storage_account_name        = azurerm_storage_account.storage_account.name
    container_access_type       = "private"
}

#******************************************************************************
# SAS token
#******************************************************************************
data "azurerm_storage_account_blob_container_sas" "account_sas" {
    connection_string           = azurerm_storage_account.storage_account.primary_connection_string
    container_name              = azurerm_storage_container.container_analysis_services.name
    https_only                  = true

    start                       = "2019-12-26"
    expiry                      = "2030-01-01"

    permissions {
        read                    = true
        write                   = true
        delete                  = true
        list                    = true
        add                     = true
        create                  = true
    }

    cache_control               = "max-age=5"
    content_disposition         = "inline"
    content_encoding            = "deflate"
    content_language            = "en-US"
    content_type                = "application/json"
}
