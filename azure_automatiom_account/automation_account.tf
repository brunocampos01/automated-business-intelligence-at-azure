# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "rg" {
    name                        = "${var.product_client_name}-rg"
    location                    = var.location
    tags                        = var.tags
}

resource "azurerm_automation_account" "automation_account" {
    name                        = "${var.product_client_name_lower}-autoacc"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    sku_name                    = "Basic"
    tags                        = var.tags
}

resource "azurerm_automation_credential" "automation_credential" {
    name                        = "application_user"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    username                    = var.application_user_login
    password                    = var.application_user_password
}

#******************************************************************************
# Modules powershell
#******************************************************************************
resource "azurerm_automation_module" "azurerm_profile" {
    name                        = "AzureRM.Profile"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    module_link {
        uri                     = "https://www.powershellgallery.com/api/v2/package/AzureRM.profile/5.8.3"
    }
}

resource "azurerm_automation_module" "azurerm_analysisservices" {
    name                        = "AzureRM.AnalysisServices"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    module_link {
        uri                     = "https://www.powershellgallery.com/api/v2/package/AzureRM.AnalysisServices/0.6.14"
    }
    depends_on                  = [azurerm_automation_module.azurerm_profile]
}

resource "azurerm_automation_module" "sqlserver" {
    name                        = "SqlServer"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    module_link {
        uri                     = "https://www.powershellgallery.com/api/v2/package/SqlServer/21.1.18206"
    }
    depends_on                  = [azurerm_automation_module.azurerm_analysisservices]
}

resource "azurerm_automation_module" "azurerm_sql" {
    name                        = "AzureRM.Sql"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    module_link {
        uri                     = "https://www.powershellgallery.com/api/v2/package/AzureRM.Sql/4.12.1"
    }
    depends_on                  = [azurerm_automation_module.sqlserver]
}
#******************************************************************************
# Runbooks
#******************************************************************************
data "local_file" "create_db_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-create-db-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "create_db_as_runbook" {
    name                        = "${var.product_client_name_lower}-create-db-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Create db in Analysis Services"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.create_db_as_runbook_file.content
}


data "local_file" "start_stop_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-start-stop-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "start_stop_as_runbook" {
    name                        = "${var.product_client_name_lower}-start-stop-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Stat and stop Analysis Services"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.start_stop_as_runbook_file.content
}


data "local_file" "apply_roles_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-apply-roles-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "apply_roles_as_runbook" {
    name                        = "${var.product_client_name_lower}-apply-roles-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Apply roles in Model Database"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.apply_roles_as_runbook_file.content
}


data "local_file" "restore_bkp_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-restore-bkp-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "restore_bkp_as_runbook" {
    name                        = "${var.product_client_name_lower}-restore-bkp-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Restore backup analysis services"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.restore_bkp_as_runbook_file.content
}


data "local_file" "send_email_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-send-email-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "send_email_runbook" {
    name                        = "${var.product_client_name_lower}-send-email-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Stat and stop anlysis services"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.send_email_runbook_file.content
}

data "local_file" "process_large_volume_tables_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-process-large-volume-tables-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "process_large_volume_tables_as_runbook" {
    name                        = "${var.product_client_name_lower}-process-large-volume-tables-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Process large volume table'"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.process_large_volume_tables_as_runbook_file.content
}

data "local_file" "process_partitions_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-daily-process-partitions-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "process_partitions_as_runbook" {
    name                        = "${var.product_client_name_lower}-daily-process-partitions-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Process daily partitions"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.process_partitions_as_runbook_file.content
}

data "local_file" "process_partitions_monthly_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-monthly-process-partitions-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "process_partitions_monthly_as_runbook" {
    name                        = "${var.product_client_name_lower}-monthly-process-partitions-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Process monthly partitions"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.process_partitions_monthly_as_runbook_file.content
}

data "local_file" "update_bkp_as_runbook_file" {
    filename                    = "${path.module}/runbooks/${var.product_client_name_lower}-update-bkp-as-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "update_bkp_as_runbook" {
    name                        = "${var.product_client_name_lower}-update-bkp-as-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Update backup file of Analysis Services"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.update_bkp_as_runbook_file.content
}

data "local_file" "update_modules_runbook_file" {
    filename                    = "${path.module}/runbooks/update-modules-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "update_modules_powershell_runbook" {
    name                        = "${var.product_client_name_lower}-update-modules-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Update modules powershell"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.update_modules_runbook_file.content
}

data "local_file" "update_automation_account_certificate_file" {
    filename                    = "${path.module}/runbooks/update-certificate-runbook.ps1"
    # Module workaround for create depends_on
    depends_on                  = [azurerm_automation_account.automation_account]
}

resource "azurerm_automation_runbook" "update_certificate_runbook" {
    name                        = "${var.product_client_name_lower}-update-certificate-runbook"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    log_verbose                 = "true"
    log_progress                = "true"
    description                 = "Update certificate of 'run as account.'"
    runbook_type                = "PowerShell"
    tags                        = var.tags
    publish_content_link {
        uri                     = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
    }
    content                     = data.local_file.update_automation_account_certificate_file.content
}

#******************************************************************************
# Schedules
#******************************************************************************
resource "azurerm_automation_schedule" "update_modules_schedule" {
    name                        = "update-modules-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Update modules of powershell"
    frequency                   = "OneTime"
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "20m")
}

resource "azurerm_automation_schedule" "create_db_as_schedule" {
    name                        = "create-db-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Create database in Azure Analysis Services"
    frequency                   = "OneTime"
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "35m")
}

resource "azurerm_automation_schedule" "start_as_schedule" {
    name                        = "start-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Start service Analysis Services"
    frequency                   = "Week"
    week_days                   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "45m")
}

resource "azurerm_automation_schedule" "process_partitions_as_schedule" {
    name                        = "process-partitions-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Process daily partitions"
    frequency                   = "Week"
    week_days                   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "55m")
}

resource "azurerm_automation_schedule" "process_large_volume_tables_as_schedule" {
    name                        = "process-large-volume-tables-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Process large volume table"
    frequency                   = "OneTime"
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "65m")
}

resource "azurerm_automation_schedule" "process_partitions_monthly_as_schedule" {
    name                        = "process-partitions-monthly-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Process monthly partitions"
    frequency                   = "Month"
    month_days                  = [1]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "70m")
}

resource "azurerm_automation_schedule" "update_backup_as_schedule" {
    name                        = "update-backup-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Update bkp Azure Analysis Services"
    frequency                   = "Week"
    week_days                   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "85m")
}

resource "azurerm_automation_schedule" "stop_as_schedule" {
    name                        = "stop-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Stop service Analysis Services"
    frequency                   = "Week"
    week_days                   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "95m")
}

resource "azurerm_automation_schedule" "stop_again_as_schedule" {
    name                        = "stop-again-as-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "If service starting manually, stop Azure Analysis Services "
    frequency                   = "Week"
    week_days                   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "100m")
}

resource "azurerm_automation_schedule" "update_certificate_schedule" {
    name                        = "update-automation-account-certificate-schedule"
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    description                 = "Update Automation Account certificate."
    frequency                   = "Month"
    month_days                  = [1]
    timezone                    = "E. South America Standard Time"
    start_time                  = timeadd(timestamp(), "90m")
}
#******************************************************************************
# Runbooks + Schedules
#******************************************************************************
resource "azurerm_automation_job_schedule" "update_modules_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.update_modules_powershell_runbook.name
    schedule_name               = azurerm_automation_schedule.update_modules_schedule.name
}

resource "azurerm_automation_job_schedule" "update_certificate_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.update_certificate_runbook.name
    schedule_name               = azurerm_automation_schedule.update_certificate_schedule.name
}

resource "azurerm_automation_job_schedule" "create_db_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.create_db_as_runbook.name
    schedule_name               = azurerm_automation_schedule.create_db_as_schedule.name
}

resource "azurerm_automation_job_schedule" "start_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.start_as_schedule.name
}

resource "azurerm_automation_job_schedule" "stop_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.stop_as_schedule.name
}

resource "azurerm_automation_job_schedule" "stop_again_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.stop_again_as_schedule.name
}

resource "azurerm_automation_job_schedule" "process_large_volume_tables_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.process_large_volume_tables_as_schedule.name
}

resource "azurerm_automation_job_schedule" "process_partitions_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.process_partitions_as_schedule.name
}

resource "azurerm_automation_job_schedule" "process_partitions_monthly_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.process_partitions_monthly_as_schedule.name
}

resource "azurerm_automation_job_schedule" "update_backup_as_job_schedule" {
    resource_group_name         = azurerm_resource_group.rg.name
    automation_account_name     = azurerm_automation_account.automation_account.name
    runbook_name                = azurerm_automation_runbook.start_stop_as_runbook.name
    schedule_name               = azurerm_automation_schedule.update_backup_as_schedule.name
}
