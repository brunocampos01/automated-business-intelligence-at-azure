param(
    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $EndpointServer = "asazure://<LOCATION>.asazure.windows.net/<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [parameter(Mandatory=$false)]
    [string] $ServerName = "<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [Parameter(Mandatory=$false)]
    [String] $DataSourceName = "Oracle SAJPMSINSIGHTS",

    [Parameter(Mandatory=$false)]
    [String] $DatabaseName = "<PRODUCT_NAME> <CLIENT_NAME>",

    [parameter(Mandatory=$false, HelpMessage="E.g.: fInfoProcessoMensal")]
    [String] $LargeVolumeTable = "<LARGE_VOLUME_TABLE>",

    [parameter(Mandatory=$false, HelpMessage="It's where of query. E.g.: idanomesreferencia")]
    [String] $ColumnToSplit = "<COLUMN_TO_SPLIT>",

    [parameter(Mandatory=$false, HelpMessage="Range of month to storage in Analysis Services")]
    [int16] $TotalMonth = "<TOTAL_MONTH>",

    [Parameter(Mandatory=$false)]
    [String] $NameUser = "application_user",

    [parameter(Mandatory=$false)]
    [string] $AutomationAccountName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc",

    [parameter(Mandatory=$false)]
    [string] $RunbookNameEmail = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-send-email-runbook"
)

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
                        ColumnToSplit: $ColumnToSplit `
                        TotalMonth: $TotalMonth `
                        NameUser: $NameUser `
                        AutomationAccountName: $AutomationAccountName `
                        RunbookNameEmail: $RunbookNameEmail" | timestamp

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

        for($m=1; $m -le $TotalMonth; $m++) {
            $Date = (Get-Date).AddMonths(-$m).ToString('yyyyMM')
            [string] $PartitionName = "$($LargeVolumeTable)_$($Date)"
            Write-Output "Executing query: $PartitionName" | timestamp

            # Query
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

                #create partition
                Write-Output "Executing query CreatePartition in $DatabaseName > $LargeVolumeTable > $PartitionName" | timestamp
                Invoke-ASCmd `
                    -Server $EndpointServer `
                    -Credential $cred `
                    -Database $DatabaseName `
                    -Query ($CreatePartition | ConvertTo-Json -Depth 25)

                Write-Output "Processing partition" | timestamp
                Invoke-ProcessPartition `
                    -Server $EndpointServer `
                    -Credential $cred `
                    -Database $DatabaseName `
                    -TableName "$LargeVolumeTable" `
                    -PartitionName "$PartitionName" `
                    -RefreshType "Full"
            }
    } else {
        Write-Warning "Services paused. Exiting" | timestamp
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

