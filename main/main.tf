module "generate_scripts" {
    source                      = "../scripts"
    client_name                 = var.client_name
    client_name_lower           = var.client_name_lower
    email_from                  = var.email_from
    email_to                    = var.email_to
    location                    = var.location
    product_client_name         = var.product_client_name
    product_client_name_lower   = var.product_client_name_lower
    product_name                = var.product_name
    data_source                 = var.data_source
    subscription_id             = var.subscription_id
    smtp_port                   = var.smtp_port
    smtp_server                 = var.smtp_server
    column_to_split             = var.column_to_split
    large_volume_table          = var.large_volume_table
    total_month                 = var.total_month
    list_admins                 = var.list_admins
    list_readers                = var.list_readers
}

module "PRODUCT_NAME_storage_account" {
    source                      = "../azure_storage_account"
    client_id                   = var.client_id
    client_name                 = var.client_name
    client_name_lower           = var.client_name_lower
    client_secret               = var.client_secret
    tenant_id                   = var.tenant_id
    location                    = var.location
    product_client_name         = var.product_client_name
    product_client_name_lower   = var.product_client_name_lower
    subscription_id             = var.subscription_id
    tags                        = var.tags
    product_name                = var.product_name
}

module "PRODUCT_NAME_automation_account" {
    source                      = "../azure_automatiom_account"
    application_user_login      = var.application_user_login
    application_user_password   = var.application_user_password
    client_id                   = var.client_id
    client_name                 = var.client_name
    client_secret               = var.client_secret
    location                    = var.location
    product_client_name         = var.product_client_name
    product_client_name_lower   = var.product_client_name_lower
    subscription_id             = var.subscription_id
    tags                        = var.tags
    tenant_id                   = var.tenant_id
}

module "PRODUCT_NAME_log_analytics" {
    source                      = "../azure_log_analytics"
    client_id                   = var.client_id
    client_name                 = var.client_name
    client_secret               = var.client_secret
    location                    = var.location
    product_client_name         = var.product_client_name
    product_client_name_lower   = var.product_client_name_lower
    subscription_id             = var.subscription_id
    tags                        = var.tags
    tenant_id                   = var.tenant_id
}

module "PRODUCT_NAME_analysis_services" {
    source                      = "../azure_analysis_services"
    list_admins_global          = var.list_admins_global
    client_id                   = var.client_id
    client_name                 = var.client_name
    client_name_lower           = var.client_name_lower
    client_secret               = var.client_secret
    location                    = var.location
    product_client_name         = var.product_client_name
    product_client_name_lower   = var.product_client_name_lower
    subscription_id             = var.subscription_id
    tags                        = var.tags
    tenant_id                   = var.tenant_id
    product_name                = var.product_name
    sas_token                   = module.PRODUCT_NAME_storage_account.sas_url_query_string
}
