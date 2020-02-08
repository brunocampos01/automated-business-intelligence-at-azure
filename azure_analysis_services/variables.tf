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

variable "product_name" {
    type = string
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

variable "list_admins_global" {
    type = list(string)
}

variable "product_client_name_lower" {
    type = string
}

variable "sas_token" {
    type = string
}
