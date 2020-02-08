#Variables declaration
variable "subscription_id" {
    description = "Azure subscription Id."
    type = string
}

variable "client_id" {
    description = "Azure service principal application Id"
    type = string
}

variable "client_secret" {
    description = "Azure service principal application Secret"
    type = string
}

variable "tenant_id" {
    description = "Azure tenant Id."
    type = string
}

variable "location" {
    type = string
    description = "Localization to create resources in Azure"
}

variable "client_name" {
    type = string
}

variable "client_name_lower" {
    type = string
}

variable "product_client_name" {
    type = string
}

variable "tags" {
    type = map
}

variable "list_admins" {
    type = string
    description = "Not possible work with list(string) in this case"
}

variable "list_readers" {
    type = string
    description = "Not possible work with list(string) in this case"
}

variable "list_admins_global" {
    type = list(string)
}

variable "product_client_name_lower" {
    type = string
}

variable "application_user_password" {
    type = string
}

variable "application_user_login" {
    type = string
}

variable "product_name" {
    type = string
}

variable "email_from" {
    type = string
}

variable "email_to" {
    type = string
}

variable "smtp_server" {
    type = string
}

variable "smtp_port" {
    type = string
}

variable "data_source" {
    type = string
}

variable "large_volume_table" {
    description = "Table name with large volume to split"
    type = string
}

variable "column_to_split" {
    description = "It's where of query TMSL."
    type = string
}

variable "total_month" {
    description = "Range of month to storage in Analysis Services"
    type = string
}
