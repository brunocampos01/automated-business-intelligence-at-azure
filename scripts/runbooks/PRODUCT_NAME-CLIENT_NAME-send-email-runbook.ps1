param(
    [parameter(Mandatory=$false)]
    [string] $NameUser = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>",

    [parameter(Mandatory=$false)]
    [string] $EmailFrom = "<EMAIL_FROM>",

    [parameter(Mandatory=$false)]
    [string] $EmailTo = "<EMAIL_TO>",

    [parameter(Mandatory=$false)]
    [string] $Port = '<SMTP_PORT>',

    [parameter(Mandatory=$false)]
    [string] $SmtpServer = '<SMTP_SERVER>',

    [parameter(Mandatory=$false)]
    [string] $Subject = "<CLIENT_NAME> - Runbook FAILED!",

    [parameter(Mandatory=$false)]
    [string] $Body = "The runbook failed. For more details, access: https://portal.azure.com/ `
                    `
                    `Resource Group: <PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg `
                    `Automation Account: <PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc `
                    `
                    `
                    `
                    `
                    `
                    "
)
#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "Stop"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

Write-Output "Parameters: `
                            NameUser: $NameUser `
                            EmailTo: $EmailTo `
                            EmailCc: $EmailCc `
                            EmailBcc: $EmailBcc `
                            EmailFrom: $EmailFrom `
                            Port: $Port `
                            SmtpServer: $SmtpServer `
                            Subject: $Subject `
                            Body: $Body " | timestamp
#******************************************************************************
# Get credentials Azure
#******************************************************************************
Write-Output "Get credentials Azure..." | timestamp

$userCredential = Get-AutomationPSCredential -Name $NameUser
$cred = New-Object -TypeName System.Management.Automation.PSCredential `
                   -ArgumentList `
                        $userCredential.UserName, `
                        $userCredential.Password
#******************************************************************************
# Send email
#******************************************************************************
Send-MailMessage `
    -From $EmailFrom `
    -To $EmailTo `
    -Cc $EmailCc `
    -Port $Port `
    -Subject $Subject `
    -Body $Body `
    -SmtpServer $SmtpServer `
    -Credential $cred `
    -Usessl `
    -Priority High

Write-Output "Email sent succesfully"
