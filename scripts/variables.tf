variable "subscription_id" {
    description = "Azure subscription Id."
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

variable "list_admins" {
    type = string
    description = "Not possible work with list(string) in this case"
}

variable "list_readers" {
    type = string
    description = "Not possible work with list(string) in this case"
}

variable "product_client_name_lower" {
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
    type = string
}

variable "column_to_split" {
    type = string
}

variable "total_month" {
    type = string
}
