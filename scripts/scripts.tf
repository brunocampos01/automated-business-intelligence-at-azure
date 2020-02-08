resource "null_resource" "generate_scripts" {
    provisioner "local-exec" {
        command                 = "${path.module}/generate_scripts.py --subscritpion_id ${var.subscription_id} --data_source ${var.data_source} --product_name ${var.product_name} --client_name ${var.client_name_lower} --large_volume_table ${var.large_volume_table} --column_to_split ${var.column_to_split} --total_month ${var.total_month} --location ${var.location} --list_admins ${var.list_admins} --list_readers ${var.list_readers} --email_from ${var.email_from} --email_to ${var.email_to} --smtp_server ${var.smtp_server} --smtp_port ${var.smtp_port}"
        interpreter             = ["Powershell", "Python"]
    }
}
