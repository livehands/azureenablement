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
$NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow
# Create a network security group
$NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule
#VM NIC Creation
$VMNICname = $vmname + "-NIC"
$VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
$nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
<#Disk Creation 
$diskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB 128
$dataDisk = New-AzDisk -ResourceGroupName $ResouceGroup -DiskName "OSDisk" -Disk $diskConfig#>
#Credential
$cred = Get-Credential
#VMconfig
$VmConfig = New-AzVMConfig  -VMName $VMname -VMSize $VMSKU | Set-AzVMOperatingSystem -Windows  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID|
# Working on this - $vmConfig = Add-AzVMDataDisk -VM $VmConfig -Name "OSDISK" -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 1
#If ($VmOS -eq "windows")
#{
New-AZVm -ResourceGroupName $Resourcegroup -Location $location -VM $vmConfig -verbose
##Cleanup
#Get-AzResourceGroup -Name $ResourceGroup | Remove-AzResourceGroup -Force

