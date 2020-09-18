using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Getting Azure Locations for Subscription..."

$subscriptionId = $env:subscriptionId
$tenantId = $env:tenantId

Write-Host "subId: " + $subscriptionId
Write-Host "TenantId: " + $tenantId

###################################
#Set Default Security
Set-AzContext -Subscription "$subscriptionId"

$locations = Get-AzureRmLocation

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $locations
})
