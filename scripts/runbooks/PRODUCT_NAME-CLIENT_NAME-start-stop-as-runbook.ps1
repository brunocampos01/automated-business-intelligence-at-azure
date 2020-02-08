param(
    [parameter(Mandatory=$false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [Parameter(Mandatory=$false)]
    [String] $NameUser = "application_user",

    [parameter(Mandatory=$false)]
    [string] $ServerName = "<PRODUCT_NAME><CLIENT_NAME_LOWER>",

    [parameter(Mandatory=$false)]
    [string] $ServiceTimeZone = "E. South America Standard Time",

    [parameter(Mandatory=$false)]
    [string] $AutomationAccountName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc",

    [parameter(Mandatory=$false)]
    [string] $RunbookNameEmail = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-send-email-runbook",

    [parameter(Mandatory=$false)]
    [string] $ConfigStr = "
                            [
                                {
                                    WeekDays:[1,2,3,4,5]
                                    ,StartTime: ""09:50:00""
                                    ,StopTime: ""10:25:00""
                                    ,Sku: ""S0""
                                }
                            ]
                          "
)
#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "Stop"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

Write-Output "Parameters: `
                        $ResourceGroupName `
                        $ServiceTimeZone `
                        $ServerName `
                        $NameUser `
                        $ConfigStr " | timestamp

#******************************************************************************
# Set Timestamp
#******************************************************************************
# Get current date/time and convert time zone
Write-Output "Handling time zone" | timestamp
Write-Output "Script started with UTC zone." | timestamp
$stateConfig = $ConfigStr | ConvertFrom-Json
$startTime = Get-Date

Write-Output "Azure Automation local time: $startTime." | timestamp
$toTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($ServiceTimeZone)
Write-Output "Time zone convert to: $toTimeZone." | timestamp
$newTime = [System.TimeZoneInfo]::ConvertTime($startTime, $toTimeZone)
Write-Output "Converted time: $newTime." | timestamp
$startTime = $newTime

# Get current day of week based on converted start time
$currentDayOfWeek = [Int]($startTime).DayOfWeek
Write-Output "Current day of week: $currentDayOfWeek." | timestamp

# Find a match in the config
$dayObjects = $stateConfig `
    | Where-Object {$_.WeekDays -contains $currentDayOfWeek} `
    | Select-Object Sku, `
    @{ Name = "StartTime"; `
    Expression = {
        [datetime]::ParseExact($_.StartTime,"HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)}}, `
    @{ Name = "StopTime";`
    Expression = {
        [datetime]::ParseExact($_.StopTime,"HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture)}}
#******************************************************************************
# Logging in to Azure
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

    # Send email
    Start-AzureRmAutomationRunbook `
        -AutomationAccountName $AutomationAccountName `
        -Name $RunbookNameEmail `
        -ResourceGroupName $ResourceGroupName

    throw $_.Exception
}
#******************************************************************************
# Azure Analysis Service
#******************************************************************************
try {
    # Get the server status
    $asServer = Get-AzureRmAnalysisServicesServer -Res $ResourceGroupName `
                                                  -Name $ServerName
    Write-Output "Azure Analysis Services STATUS: $($asServer.State)" | timestamp

    # If not match any day then exit
    if($dayObjects -ne $null) {
        # Can't treat several objects for same time-frame, if there's more than one, pick first
        $matchingObject = $dayObjects | Where-Object {($startTime -ge $_.StartTime) -and ($startTime -lt $_.StopTime)} | Select-Object -First 1

        if($matchingObject -ne $null) {
            # if Paused resume
            if($asServer.State -eq "Paused") {
                Write-Output "Resuming..." | timestamp
                $asServer | Resume-AzureRmAnalysisServicesServer -Verbose
            }
        }else {
            if($asServer.State -eq "Succeeded"){
                Write-Output "Pausing services..." | timestamp
                $asServer | Suspend-AzureRmAnalysisServicesServer -Verbose
            }
        }
    }else {
        Write-Output "No object config for current day of week" | timestamp
        if($asServer.State -eq "Succeeded") {
            $asServer | Suspend-AzureRmAnalysisServicesServer -Verbose
        }
    }
} catch {
    Write-Output "`n`nFAILED !"
    Write-Output $ResourceGroupName
    Write-Output $ServerName
    Write-Output $serviceTimeZone
    Write-Output $currentDayOfWeek
    Write-Output "$($_.Exception.Message)" | timestamp

    # Send email
    Start-AzureRmAutomationRunbook `
        -AutomationAccountName $AutomationAccountName `
        -Name $RunbookNameEmail `
        -ResourceGroupName $ResourceGroupName

    throw $_.Exception
} finally {
    Write-Output "--- Script finished ---" | timestamp
}
