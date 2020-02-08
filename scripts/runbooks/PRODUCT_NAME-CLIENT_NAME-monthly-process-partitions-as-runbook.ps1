param(
    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $EndpointServer = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory=$false)]
    [String] $DataSourceName = "DataSourceName",

    [Parameter(Mandatory=$false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [parameter(Mandatory=$false, HelpMessage="E.g.: fInfoProcessoMensal")]
    [String] $LargeVolumeTable = "<LARGE_VOLUME_TABLE>",

    [parameter(Mandatory=$false, HelpMessage="It's where of query. E.g.: idanomesreferencia")]
    [String] $ColumnToSplit = "<COLUMN_TO_SPLIT>",

    [parameter(Mandatory=$false)]
    [string] $ServerName = "<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory=$false)]
    [String] $NameUser = "application_user",

    [Parameter(Mandatory=$false, HelpMessage="Append accumulates the data. Range is the same as Append and does another function which is to delete the last month. Every keep a range (TotalMonth)")]
    [ValidateSet("append", "range")]
    [String] $ProcessingType = "append",

    [parameter(Mandatory=$false)]
    [string] $AutomationAccountName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc",

    [parameter(Mandatory=$false)]
    [string] $RunbookNameEmail = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-send-email-runbook"
)

#******************************************************************************
# Dates
#******************************************************************************
[string] $Date = (Get-Date).AddMonths(-1).ToString('yyyyMM')
[string] $LastMonth = (Get-Date).AddMonths(-1).ToString('MM') # get last month to create partition
[string] $LastYear = (Get-Date).AddYears(-1).ToString('yyyy')

#******************************************************************************
# Query TMSL
#******************************************************************************
[string] $PartitionName = "$($LargeVolumeTable)_$($Date)"
[string] $PartitionNameToDelete = "$($LargeVolumeTable)_$($LastYear)$($LastMonth)"

$CreatePartition = @"
{
  "createOrReplace": {
    "object": {
      "database": "$DatabaseName",
      "table": "$LargeVolumeTable",
      "partition": "$PartitionName"
    },
    "partition": {
      "name": "$PartitionName",
      "source": {
        "type": "query",
        "query": "SELECT * FROM \"$LargeVolumeTable\" WHERE $ColumnToSplit = $Date",
        "dataSource": "$DataSourceName"
      },
      "annotations": [
        {
          "name": "QueryEditorSerialization",
          "value": "<?xml version=\"1.0\" encoding=\"UTF-16\"?><Gemini xmlns=\"QueryEditorSerialization\"><AnnotationContent><![CDATA[<RSQueryCommandText>SELECT * FROM \"$LargeVolumeTable\" WHERE $ColumnToSplit = $Date</RSQueryCommandText><RSQueryCommandType>Text</RSQueryCommandType><RSQueryDesignState></RSQueryDesignState>]]></AnnotationContent></Gemini>"
        }
      ]
    }
  }
}
"@ | ConvertFrom-Json

$DeletePartition = @"
{
  "delete": {
    "object": {
      "database": "$DatabaseName",
      "table": "$LargeVolumeTable",
      "partition": "$PartitionNameToDelete"
    }
  }
}
"@ | ConvertFrom-Json

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
                        DataSourceName: $DataSourceName `
                        DatabaseName: $DatabaseName `
                        LargeVolumeTable: $LargeVolumeTable `
                        ProcessingType: $ProcessingType `
                        PartitionName: $PartitionName `
                        NameUser: $NameUser `
                        AutomationAccountName: $AutomationAccountName `
                        RunbookNameEmail: $RunbookNameEmail `
                        Date: $Date `
                        LastYear: $LastYear `
                        LastMonth: $LastMonth" | timestamp

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
    Write-Output "Resuming..." | timestamp
    $asServer | Resume-AzureRmAnalysisServicesServer -Verbose

    # Create partition
    Write-Output "Executing query: CreatePartition" | timestamp
    Invoke-ASCmd `
        -Database $DatabaseName `
        -Server $EndpointServer `
        -Credential $cred `
        -Query ($CreatePartition | ConvertTo-Json -Depth 25)

    Write-Output "Processing : $PartitionName" | timestamp
    Invoke-ProcessPartition `
        -Server $EndpointServer `
        -Credential $cred `
        -Database $DatabaseName `
        -TableName $LargeVolumeTable `
        -PartitionName $PartitionName `
        -RefreshType "Full"

    # Defragment
    Write-Output "Defragmenting" | timestamp
    Invoke-ProcessASDatabase `
        -DatabaseName $DatabaseName `
        -Server $EndpointServer `
        -Credential $cred `
        -RefreshType "Defragment"

    if($ProcessingType -eq "range") {
        # Delete partition
        Write-Output "Executing query: $DeletePartition" | timestamp
        Invoke-ASCmd `
            -Server $EndpointServer `
            -Credential $cred `
            -Database $DatabaseName `
            -Query ($DeletePartition | ConvertTo-Json -Depth 25)
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
    Write-Output "Pausing services..." | timestamp
    $asServer | Suspend-AzureRmAnalysisServicesServer -Verbose

    Write-Output "--- Script finished ---" | timestamp
}
