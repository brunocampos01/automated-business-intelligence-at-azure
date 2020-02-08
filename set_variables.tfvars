# Azure
subscription_id = "11111111-aaaa-aaaa-aaaa-11111111"
client_id = "11111111-aaaa-aaaa-aaaa-11111111"
client_secret = "11111111-aaaa-aaaa-aaaa-11111111"
tenant_id = "11111111-aaaa-aaaa-aaaa-11111111"

location = "brazilsouth"

tags =  {
    analytics = "bi"
    PRODUCT_NAME = "cocams"
}

# User with access in portal Azure. Cannot be terraform user
application_user_login = "application_user@gmail.com"
application_user_password = "#123!"

# Client and product name
client_name = "cocaAA"
client_name_lower = "cocaaa"
product_name = "PRODUCT_NAME"
product_client_name = "PRODUCT_NAME-cocaAA"
product_client_name_lower = "PRODUCT_NAME-cocaaa"

# If Runbooks fail, send email
email_from = "smtp@cococaany.com.br"
email_to = "brunocampos01@cococaany.com.br"
smtp_server = "email-smtp.us-west-2.amazonaws.com"
smtp_port = "587"

# Data source
data_source = "oracle"

# Analysis Services
large_volume_table = "fact"
column_to_split = "id_collumn_name"
total_month = "12"

# Acess root in everyone databases of analysis services
list_admins_global = [
    "application_user@gmail.com",
    "brunocampos01@gmail.com"
]

# Thes logins must be separeted without spaces
list_admins =  "application_user@gmail.com"

# Thes logins must be separeted without spaces
list_readers = "brunocampos01@gmail.com,application_user@gmail.com"
