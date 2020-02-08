<#
    .SYNOPSIS
        Restore backup Azure Analysis Services automated

    .PARAMETER serverName
        The Azure Analysis Service Server endpoint

    .PARAMETER databaseName
        The Analysis Service Database

    .PARAMETER name_user
        name_user

    .PARAMETER BkpFileName
        The BkpFileName
#>
Param (
    [parameter(Mandatory=$false)]
    [string] $ServerName = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory = $false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [Parameter(Mandatory = $false)]
    [String] $NameUser = "application_user",

    [Parameter(Mandatory = $false)]
    [String] $BkpFileName = "bkp_azure_analysis_services.abf"
)

#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "Stop"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

Write-Output "Parameters: `
                        $EndpointServer `
                        $DatabaseName `
                        $NameUser " | timestamp
#******************************************************************************
# Logging into Azure
#******************************************************************************
Write-Output "Logging in to Azure..." | timestamp

try {
    # Ensures you do not inherit an AzureRMContext in your runbook
    Disable-AzureRmContextAutosave -Scope Process

    $connection = Get-AutomationConnection -Name "AzureRunAsConnection"

    while(!($connectionResult) -And ($logonAttempt -le 10)) {
        $LogonAttempt++
        # Logging in to Azure...
        $connectionResult = Login-AzureRmAccount `
                                -ServicePrincipal `
                                -Tenant $connection.TenantID `
                                -ApplicationID $connection.ApplicationID `
                                -CertificateThumbprint $connection.CertificateThumbprint

        Start-Sleep -Seconds 5
    }

} catch {
    Write-Output "Logging FAILED !" | timestamp
    Write-Output "connection: $connection"
    Write-Output $_.Exception
    Write-Error -Message $_.Exception

    throw $_.Exception
}
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
# Restore backup Azure Analysis Service
#******************************************************************************
try {
    Write-Output "Starting restore..." | timestamp
    Restore-ASDatabase `
        -RestoreFile $BkpFileName `
        -Server $ServerName `
        -Name $DatabaseName `
        -Credential $cred

} catch {
    Write-Output "Restore FAILED !`n" | timestamp
    Write-Output $userCredential
    Write-Output $cred
    Write-Output "$($_.Exception.Message)"

    throw $_.Exception
} finally {
    Write-Output "--- Script finished ---" | timestamp
}
