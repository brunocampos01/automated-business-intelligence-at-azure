## Module: BI Azure

- Azure Analysis Services
- Azure Storage Account
- Azure Automation Account
- Azure Log Analytics
- Generator scripts for runbooks

## Requisites
- Powershell
```powershell
❯ $psversiontable

Name                           Value
----                           -----
PSVersion                      5.1.18362.145
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.18362.145
CLRVersion                     4.0.30319.42000
WSManStackVersion              3.0
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
```

- Terraform
```powershell
❯ terraform --version

# Terraform v0.12.7
# + provider.azurerm v1.39.0
# + provider.local v1.4.0
# + provider.null v2.1.2
```

## Limitations
- Automation Account need manual approve the execution `runAsAccount`
- Issues: https://github.com/terraform-providers/terraform-provider-azurerm/issues/4431

