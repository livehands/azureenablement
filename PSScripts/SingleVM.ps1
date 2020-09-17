#>
param
(
   [Parameter(Mandatory=$true)]
   $ResourceGroup,
   [Parameter(Mandatory=$true)]
   $VNETNAME,
   [Parameter(Mandatory=$true)]
   $Location,
   [Parameter(Mandatory=$true)]
   $VNETAddress,
   [Parameter(Mandatory=$true)]
   $subnetAddress,
   [Parameter(Mandatory=$true)]
   $OS,
   [Parameter(Mandatory=$true)]
   $VMSKU    
 )
#Static Variable
$SubnetName = 'MGMTSubnet'
$pubIP = 'VMPublicIP'
$PIPsku = 'Basic'
$PIPalloc = 'dynamic'
$VMname = 'test'
#Resource Group  Creation
New-AZResourceGroup -Name $Resourcegroup -Location $location
#VNET Creation
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddress
# Create a virtual network
$VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VNETNAME -AddressPrefix $VNETAddress -Subnet $subnetConfig
# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $VNet
#Public IP address Creation
$vmpip=New-AzPublicIpAddress -ResourceGroupName $Resourcegroup -Name $pubIP -Location $location -AllocationMethod $PIPalloc -SKU $PIPsku 
#NSG Rule and Config
$#NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow
#Credential
$cred = Get-Credential
switch ($os){
    {$_ -eq "windows" } {
        #NSG Rule and Config
        $NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow;
         # Create a network security group
        $NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule;
        $VMNICname = $vmname + "-NIC"
        $VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
        $nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
       # $vmconfig = Set-AzVMOperatingSystem -Windows  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest;
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
       # $vmconfig = Set-AzVMOperatingSystem -Linux  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName Canonical -Offer WindowsServerUbuntuServer -Skus 14.04.2-LTS -Version latest;
        break}
    }
                    
   
#VMconfig
New-AZVm -ResourceGroupName $Resourcegroup -Location $location -VM $vmConfig -verbose
##Cleanup
#Get-AzResourceGroup -Name $ResourceGroup | Remove-AzResourceGroup -Force


