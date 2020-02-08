<#
.SYNOPSIS
    This sample automation runbook checks if the RunAs service principal certificate authentication is about to expire, and
    automatically updates it with a new certificate.
#>
Param (
    [Parameter(Mandatory = $false)]
    [string] $ResourceGroupName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-rg",

    [parameter(Mandatory=$false)]
    [string] $AutomationAccountName = "<PRODUCT_NAME>-<CLIENT_NAME_LOWER>-autoacc",

    [Parameter(Mandatory = $false)]
    [String] $SubscriptionId = "<SUBSCRIPTION_ID>",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Monthly", "Weekly")]
    [string] $ScheduleRenewalInterval = "Weekly",

    [Parameter(Mandatory = $false)]
    [ValidateSet("AzureCloud", "AzureUSGovernment", "AzureChinaCloud")]
    [string] $EnvironmentName = "AzureCloud"
)

#******************************************************************************
# Runbook logs
#******************************************************************************
$ErrorActionPreference = "stop"
filter timestamp {"[$(Get-Date -Format G)]: $_"}
Write-Output "Script started with UTC zone." | timestamp

$CertifcateAssetName = "AzureRunAsCertificate"
$ConnectionAssetName = "AzureRunAsConnection"
$ConnectionTypeName = "AzureServicePrincipal"

# Get RunAs certificate and check for expiration date. If it is about to expire in less than a week, update it.
$RunAsCert = Get-AutomationCertificate -Name $CertifcateAssetName
if ($RunAsCert.NotAfter -gt (Get-Date).AddDays(30)) {
    Write-Output ("Certificate will expire at " + $RunAsCert.NotAfter)  | timestamp
    Exit(1)
}
#******************************************************************************
# Logging into Azure
#******************************************************************************
Write-Output "Logging in to Azure..." | timestamp

try {
    # Ensures you do not inherit an AzureRMContext in your runbook
    Disable-AzureRmContextAutosave -Scope Process

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

    throw $_.Exception
}
#******************************************************************************
$RunAsConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
$Context = Set-AzureRmContext -SubscriptionId $SubscriptionId
$AutomationResource = Get-AzureRmResource -ResourceType Microsoft.Automation/AutomationAccounts
#******************************************************************************
Write-Output "Updating RunAsAccount certificate"

# Create RunAs certificate
$SelfSignedCertNoOfMonthsUntilExpired = 12
$SelfSignedCertPlainPassword = (New-Guid).Guid
$CertificateName = $AutomationAccountName + $CertifcateAssetName
$PfxCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".pfx")
$CerCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".cer")

# Create a self-signed root certificate
$cert = New-SelfSignedCertificate `
    -Type Custom `
    -KeySpec Signature `
    -Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

$Cert = New-SelfSignedCertificate -Type Custom `
                                  -DnsName $CertificateName `
                                  -KeySpec Signature `
                                  -Subject "CN=P2SChildCert"`
                                  -KeyExportPolicy Exportable `
                                  -HashAlgorithm sha256 -KeyLength 2048 `
                                  -CertStoreLocation "Cert:\LocalMachine\My" `
                                  -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") `
                                  -NotBefore (Get-Date).AddDays(-1) `
                                  -NotAfter (Get-Date).AddMonths($SelfSignedCertNoOfMonthsUntilExpired) `

$CertPassword = ConvertTo-SecureString $SelfSignedCertPlainPassword -AsPlainText -Force
Export-PfxCertificate -Cert ("Cert:\LocalMachine\My\" + $Cert.Thumbprint) -FilePath $PfxCertPathForRunAsAccount -Password $CertPassword -Force | Write-Verbose
Export-Certificate -Cert ("Cert:\LocalMachine\My\" + $Cert.Thumbprint) -FilePath $CerCertPathForRunAsAccount -Type CERT | Write-Verbose

# Update the certificate
Set-AzureRmAutomationCertificate `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Path $PfxCertPathForRunAsAccount `
    -Name $CertifcateAssetName `
    -Password $CertPassword `
    -Exportable:$true `
    -AzureRmContext $Context | Write-Verbose

Write-Output ("RunAs certificate credentials have been updated")
