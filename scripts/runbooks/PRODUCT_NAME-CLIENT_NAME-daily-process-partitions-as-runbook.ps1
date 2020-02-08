param(
    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $EndpointServer = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory=$false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [parameter(Mandatory=$false)]
    [string] $ServerName = "<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory=$false)]
    [String] $NameUser = "application_user",

    [parameter(Mandatory=$false)]
    [string] $AutomationAccountName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc",

    [parameter(Mandatory=$false)]
    [string] $RunbookNameEmail = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-send-email-runbook"
)

#******************************************************************************
# Partitions
#******************************************************************************
$listPartitions = @<LIST_PARTITIONS>

#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "Stop"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

Write-Output "PARAMETERS: `
                        ResourceGroupName: $ResourceGroupName `
                        EndpointServer: $EndpointServer `
                        ServerName: $ServerName `
                        NameUser: $NameUser `
                        AutomationAccountName: $AutomationAccountName `
                        RunbookNameEmail: $RunbookNameEmail" | timestamp

# Set action if error
$ErrorActionPreference = "Stop"

#******************************************************************************
# Logging into Azure
#******************************************************************************
Write-Output "Logging in to Azure..." | timestamp

try {
    # Ensures you do not inherit an AzureRMContext in your runbook
    Disable-AzureRmContextAutosave –Scope Process

    $connection = Get-AutomationConnection -Name AzureRunAsConnection

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

    # Send email
    Start-AzureRmAutomationRunbook `
        -AutomationAccountName $AutomationAccountName `
        -Name $RunbookNameEmail `
        -ResourceGroupName $ResourceGroupName

    throw $_.Exception
}

#******************************************************************************
# Get credentials Azure
#******************************************************************************
Write-Output "Get credentials Azure..." | timestamp

$userCredential = Get-AutomationPSCredential -Name $NameUser
$cred = New-Object -TypeName System.Management.Automation.PSCredential `
                       -ArgumentList $userCredential.UserName,
                                     $userCredential.Password

#******************************************************************************
# Azure Analysis Service
#******************************************************************************
try {
    # Get the server status
    $asServer = Get-AzureRmAnalysisServicesServer -Res $ResourceGroupName `
                                                  -Name $ServerName
    Write-Output "Azure Analysis Services STATUS: $($asServer.State)" | timestamp

    if($asServer.State -eq "Succeeded") {

        foreach ($element in $listPartitions) {
            Write-Output "Executing query process_partitions: $element" | timestamp

            Invoke-ProcessPartition `
                -Server $EndpointServer `
                -Credential $cred `
                -Database $DatabaseName `
                -TableName $element `
                -PartitionName $element `
                -RefreshType "Full"
        }
    }else {
        Write-Warning "Services paused. Exiting"
    }

} catch {
    Write-Output "FAILED !" | timestamp
    Write-Output $ResourceGroupName
    Write-Output $ServerName
    Write-Output "$($_.Exception.Message)"

    # Send email
    Start-AzureRmAutomationRunbook `
        -AutomationAccountName $AutomationAccountName `
        -Name $RunbookNameEmail `
        -ResourceGroupName $ResourceGroupName

    throw $_.Exception

} finally {
    Write-Output "--- Script finished ---" | timestamp
}
