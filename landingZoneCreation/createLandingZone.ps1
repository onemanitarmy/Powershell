# Context #
<#
Create a script to use multiple existing modules to deploy a Landing Zone #useScriptsInsteadOfWritingStuffManuallyInTerminal:)
- Workload
- Resource Group
- VNets
- Subnets
#>
# Use Line 2 - 10 with F8 and then run the rest of the script.
# Import Module
$profile

# Get DB Credentials (Manual Input)
$credential = Get-Credential

## Import Module
Import-Module .\<module_name>

## Set database credentials
# Before using the module, set the database credentials for your environment (dev | prd - 'acc' will be released in the future):
Set-DatabaseCredential -DatabaseTennant 'OTA' -UserName $credential.UserName -SecurePassword $credential.Password

## LANDING ZONE
############################## CHANGE VARIABLE OUTPUT ##############################

# Landing Zone configuration
$workloadName                   = "Test_Landing_Zone"
$businessPlatformName           = "Test_Business_Platform"
$departmentCode                 = 123456
$projectCode                    = 123456
$shortDescription               = "Test Landing Zone Deployment"
$technicalContact               = "mert@onemanitarmy.com"
$financialContact               = "mert@onemanitarmy.com"

# Resource Group Configuration
$resourceGroupNames = @(
    "aznrg001"
    "azprg001"
)

# VNet Configuration
$global:networkConfigs = @(
    @{ environment = "n"; addressSpace = "10.1.1.0/24" },
    @{ environment = "p"; addressSpace = "10.1.2.0/24" }
)

# Subnet Configuration (keep the same order as VNet Configuration)
# !!! Code is not written to create multiple subnets in the same VNet !!! #
$global:subnetConfigs = @(
    @{ subnetName = "sn0_pe"; addressPrefixes = "10.1.1.0/27" },
    @{ subnetName = "sn0_pe"; addressPrefixes = "10.1.2.0/27" }
)

############################## CHANGE VARIABLE OUTPUT ##############################

###### DO NOT TOUCH ANYTHING BELOW THIS ######

# Creates Landing Zone
$createWorkload = Add-<module_name> -WorkloadName $workloadName -BusinessPlatformName $businessPlatformName -departmentCode $departmentCode -projectCode $projectCode -ShortDescription $shortDescription -TechnicalContact $technicalContact -FinancialContact $financialContact

Write-Host "Creating Landing Zone $workloadName ... $createWorkload ..." -ForegroundColor Cyan
Write-Host "Landing Zone $workloadName has been created successfully!" -ForegroundColor Green

# Get last Workload ID for creation of Resource Groups (after the current workload has been created)
$workloadId = $createWorkload.Id

# Prints the Workload ID + New Resource Groups that are being created.
Write-host "New Workload ID: $workloadId" -ForegroundColor Yellow

# Insert $workloadId at the 3rd character of each resource group name
$newResourceGroupNames = $resourceGroupNames | ForEach-Object { $_.Insert(2, "$workloadId") }
Write-host "New Resource Groups: $($newResourceGroupNames -join ', ')" -ForegroundColor Yellow

# Creates Resource Groups
$createResourceGroups = Add-<module_name> -ResourceGroups $newResourceGroupNames
Write-Host "Creating Resource Groups for Landing Zone $workloadName ... $createResourceGroups ..." -ForegroundColor Cyan
Write-Host "Resource Groups created successfully: $($newResourceGroupNames -join ', ')" -ForegroundColor Green


## VNET CONFIGURATION
# Create VNet
foreach ($networkCount in $networkConfigs) {
    $network = Add-<module_name> `
        -WorkloadId $workloadId `
        -Environment $networkCount.environment `
        -AddressSpace $networkCount.addressSpace

    $networkId = $network.NetworkId
    Write-Host "Created Network with ID: $($networkId) for Environment: $($networkCount.environment), AddressSpace: $($networkCount.addressSpace)" -ForegroundColor Green
}

# Get all Network IDs for the created workload
$getNetworkIds = Get-<module_name> -WorkloadId $workloadId | Select-Object -ExpandProperty Id

# Loop through each Network ID and Subnet configuration
for ($count = 0; $count -lt $getNetworkIds.Count; $count++) {
    # Process each network ID and Subnet configuration
    $networkId = $getNetworkIds[$count]
    $subnetConfig = $global:subnetConfigs[$count]

    $subnet = Add-<module_name> `
        -NetworkId $networkId `
        -SubnetName $subnetConfig.subnetName `
        -AddressPrefixes $subnetConfig.addressPrefixes

    Write-Host "Created Subnet with ID: $($subnet.SubnetId) for Network ID: $($networkId), Subnet Name: $($subnetConfig.subnetName), Address Prefixes: $($subnetConfig.addressPrefixes)" -ForegroundColor Green
}

