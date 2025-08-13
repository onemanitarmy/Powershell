# Context #
<#
NSG Flow Logs were deprecating and Microsoft recommended to go over to VNet Flow logs.
Customer has implemented VNet Flow Logs on all subscriptions but requested me to disable all the current NSG Flow Logs of all subscriptions.
#>


# 1. Select a line -> Press F8 and it will run the selected line in the terminal.

# Login to Azure
Connect-AzAccount

# Opens a windows to select the output you want and it will be saved in the variable itself.
$list = Get-AzSubscription | Out-GridView -PassThru

# Variables
$networkWatcherName = "NetworkWatcher_westeurope" # Network Watcher Name
$rgNetworkWatcherName = "NetworkWatcherRG" # Resource Group Name

# For Loop in each subscription-name in $list (list of subscription names)
foreach ($subscription in $list) {
    # Set the context to the selected subscription
    Set-AzContext -SubscriptionId $subscription.Id
    Write-Host "Current Subscription: $($subscription.Name)" -ForegroundColor Yellow

    # Get NetworkWatcher and only check NSG Flow Logs.
    $networkWatcher = Get-AzNetworkWatcherFlowLog -NetworkWatcherName $networkWatcherName  -ResourceGroupName $rgNetworkWatcherName -Name "*nsg*"

    # Get only the resource names of the NSG Flow Logs from the $networkWatcher output.
    $networkWatcherNames = $networkWatcher | Select-Object -ExpandProperty Name

    # Loop through each $networkWatcherNames and remove the NSG Flow Logs.
    foreach ($nsgFlowLogName in $networkWatcherNames) {
        try {
            Write-Host "Removing NSG Flow Log: $nsgFlowLogName ..." -ForegroundColor Cyan
            Remove-AzNetworkWatcherFlowLog -Name $nsgFlowLogName -NetworkWatcherName $networkWatcherName -ResourceGroupName $rgNetworkWatcherName
            Write-Host "NSG Flow Log: $nsgFlowLogName succesfully removed!" -ForegroundColor Green      
        }
        catch {
            Write-Host "Error removing NSG Flow Log: $nsgFlowLogName" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}
