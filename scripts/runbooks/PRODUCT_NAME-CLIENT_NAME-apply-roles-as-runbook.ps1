<#
    .SYNOPSIS
        Apply access policy roles in Azure Analysis Services

    .PARAMETER server_name
        The Azure Analysis Service Server endpoint

    .PARAMETER DatabaseName
        The Analysis Service Database
#>
param(
    [parameter(Mandatory=$false)]
    [string] $EndpointServer = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory = $false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [Parameter(Mandatory = $false)]
    [String] $NameUser = "application_user",

    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $ServerName = "<PRODUCT_NAME><CLIENT_NAME_LOWER>"
)

# Query
$role_admins = @"
<SCRIPT_ROLE_ADMINS>
"@ | ConvertFrom-Json

$role_readers = @"
<SCRIPT_ROLE_READERS>
"@ | ConvertFrom-Json

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
# Azure Analysis Service
#******************************************************************************
try {
    # Get the server status
    $asServer = Get-AzureRmAnalysisServicesServer -Res $ResourceGroupName `
                                                  -Name $ServerName
    Write-Output "Azure Analysis Services STATUS: $($asServer.State)" | timestamp

    # Download file
    if($asServer.State -eq "Succeeded") {
        Write-Output "Executing query: $role_admins" | timestamp
        Invoke-ASCmd `
            -Server $EndpointServer `
            -Credential $cred `
            -Database $DatabaseName `
            -Query ($role_admins | ConvertTo-Json -Depth 25)


        Write-Output "Executing query: $role_readers" | timestamp
        Invoke-ASCmd `
            -Server $EndpointServer `
            -Credential $cred `
            -Database $DatabaseName `
            -Query ($role_readers | ConvertTo-Json -Depth 25)

    }else {
        Write-Warning "Services paused. Exiting"
    }

} catch {
    Write-Output "FAILED !" | timestamp
    Write-Output $ResourceGroupName
    Write-Output $ServerName
    Write-Output "$($_.Exception.Message)"

    throw $_.Exception
} finally {
    Write-Output "--- Script finished ---" | timestamp
}
