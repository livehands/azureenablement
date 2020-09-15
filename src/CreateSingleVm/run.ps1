using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
if (-not $name) {
    $name = $Request.Body.Name
}

$params = $request.Body

$tags = $body.Tags
$resourceGroup = $body.resourceGroup
$vnetName = $body.vnetName
$location = $body.location
$vnetAddress = $body.vnetAddress
$subnetAddress = $body.subnetAddress
$vmSku = $body.vmSku
$vmName = $body.vmName

$subnetName = $body.subnetName
if(-not $subnetName) {
    $subnetName = "MGMTSubnet"
}

#Resource Group  Creation
New-AZResourceGroup -Name $resourcegroup -Location $location
#VNET Creation
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddress
# Create a virtual network
$VNet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name $vnetName -AddressPrefix $vnetAddress -Subnet $subnetConfig
# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $VNet
#Public IP address Creation
$vmpip=New-AzPublicIpAddress -ResourceGroupName $resourcegroup -Name $pubIP -Location $location -AllocationMethod $PIPalloc -SKU $PIPsku 
#NSG Rule and Config
$NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow
# Create a network security group
$NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $resourcegroup  -Location $location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule
#VM NIC Creation
$VMNICname = $vmName + "-NIC"
$VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
$nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $resourcegroup -Location $location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
<#Disk Creation 
$diskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB 128
$dataDisk = New-AzDisk -ResourceGroupName $ResouceGroup -DiskName "OSDisk" -Disk $diskConfig#>
#Credential
$cred = Get-Credential
#VMconfig
$VmConfig = New-AzVMConfig  -VMName $vmName -VMSize $VMSKU | Set-AzVMOperatingSystem -Windows  -ComputerName $vmName -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID|
# Working on this - $vmConfig = Add-AzVMDataDisk -VM $VmConfig -Name "OSDISK" -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 1
#If ($VmOS -eq "windows")
#{
 New-AZVm -ResourceGroupName $resourcegroup -Location $location -VM $vmConfig -verbose

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $VmConfig
})
