<#
    .SYNOPSIS
        Create database in Azure Analysis Services

    .PARAMETER server_name
        The Azure Analysis Service Server endpoint

    .PARAMETER DatabaseName
        The Analysis Service Database
#>
param(
    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $EndpointServer = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory = $false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [Parameter(Mandatory = $false)]
    [String] $NameUser = "application_user"
)

# Query
$create_db = @"
<SCRIPT_CREATE_DB>
"@ | ConvertFrom-Json
#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "Continue"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

Write-Output "Parameters: `
                        $EndpointServer `
                        $DatabaseName `
                        $NameUser `
                        $FileReaders `
                        $FileAdmins " | timestamp
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
    Write-Output "Executing query: $create_db" | timestamp

    Invoke-ASCmd `
        -Server $EndpointServer `
        -Credential $cred `
        -Query ($create_db | ConvertTo-Json -Depth 25)
} catch {
    Write-Output "FAILED !" | timestamp
    Write-Output $ResourceGroupName
    Write-Output $ServerName
    Write-Output "$($_.Exception.Message)"

    throw $_.Exception
} finally {
    Write-Output "--- Script finished ---" | timestamp
}
