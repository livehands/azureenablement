using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Starting Create Single VM..."

$body = $Request.Body

$tags = $body.tags
$resourceGroup = $body.resourceGroup
$vnetName = $body.vnetName
$location = $body.location
$vnetAddress = $body.vnetAddress
$subnetAddress = $body.subnetAddress
$vmSku = $body.vmSku
$vmName = $body.vmName
$Username = $body.Username
$Password = $body.Password
$os=$body.os

#Static Variable
$SubnetName = 'MGMTSubnet'
$pubIP = 'VMPublicIP'
$PIPsku = 'Basic'
$PIPalloc = 'dynamic'

$subnetName = $body.subnetName
if(-not $subnetName) {
    $subnetName = "MGMTSubnet"
}

#Resource Group  Creation
Write-Host "Creating RG..."
#Resource Group  Creation
New-AZResourceGroup -Name $Resourcegroup -Location $location 

Write-Host "Creating VNet..."
#VNET Creation
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddress
# Create a virtual network
$VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VNETNAME -AddressPrefix $VNETAddress -Subnet $subnetConfig 
# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $VNet
#Public IP address Creation
$vmpip=New-AzPublicIpAddress -ResourceGroupName $Resourcegroup -Name $pubIP -Location $location -AllocationMethod $PIPalloc -SKU $PIPsku 

#Credential & Config
Write-Host "Configure VM & NSG..."
Write-Host "The OS is: " + $os
#Convert to SecureString
$secStringPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
switch ($os){
    {$_ -eq "windows" } {
        #NSG Rule and Config
        $NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow;
         # Create a network security group
        $NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule;
        $VMNICname = $vmname + "-NIC"
        $VMIpConfig = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
        $nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
        $VmConfig = New-AzVMConfig  -VMName $VMname -VMSize $VMSKU | Set-AzVMOperatingSystem -Windows  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID;
        break}
    {$_ -eq "Ubuntu"} {
        $NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 22 -Access Allow;
         # Create a network security group
        $NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule;
        $VMNICname = $vmname + "-NIC"
        $VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
        $nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
        $VmConfig = New-AzVMConfig  -VMName $VMname -VMSize $VMSKU | Set-AzVMOperatingSystem  -Linux  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName Canonical -Offer WindowsServerUbuntuServer -Skus 14.04.2-LTS -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID;
        break}
    }
    


Write-Host "Create VM"
#VMconfig
New-AZVm -ResourceGroupName $Resourcegroup -Location $location -VM $VmConfig -verbose

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $VmConfig
})
