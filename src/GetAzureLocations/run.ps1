using namespace System.Net
using namespace System.Collections

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
Set-AzContext -Subscription $subscriptionId

$response = Get-AzLocation

$locations = @()

foreach ($item in $response) {
    $newLocation = @{
                     location=$item.Location
                     displayName=$item.DisplayName
                    }
    $locations += $newLocation
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $locations
})
