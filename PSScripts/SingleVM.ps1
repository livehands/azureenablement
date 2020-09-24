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
   $Password,
   [Parameter(Mandatory=$true)]
   $VMSKU    
 )
#Static Variable
$SubnetName = 'MGMTSubnet'
$pubIP = 'VMPublicIP'
$PIPsku = 'Basic'
$PIPalloc = 'dynamic'
$VMname = 'test'
$storageaccountname = 'bdiagstr'+ $ResourceGroup
$vmusername = 'jtariqadmin'
#supress warning
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
#Resource Group  Creation
write-host "Creating Resource Group"
New-AZResourceGroup -Name $Resourcegroup -Location $location
#VNET Creation
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddress
# Create a virtual network
$VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Location $Location -Name $VNETNAME -AddressPrefix $VNETAddress -Subnet $subnetConfig
# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $VNet
#Public IP address Creation
write-host "Creating PIP"
$vmpip=New-AzPublicIpAddress -ResourceGroupName $Resourcegroup -Name $pubIP -Location $location -AllocationMethod $PIPalloc -SKU $PIPsku 
#Creating Storage account for boot diagnostics
$storageAccount = New-AzStorageAccount -ResourceGroupName $Resourcegroup -Name $storageaccountname -SkuName Standard_LRS   -Location $location 
#disk profile creation 
#$diskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB 128
#$OSdisk = New-AzDisk -ResourceGroupName $Resourcegroup -DiskName "OSDisk" -Disk $diskConfig
#Credential
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($vmusername, $securePassword)
#$cred = Get-Credential
switch ($os){
    {$_ -eq "windows" } {
         write-host "Creating Windows Profile"
        #NSG Rule and Config
        $NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 3389 -Access Allow;
         # Create a network security group
        $NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule;
        $VMNICname = $vmname + "-NIC"
        $VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
        $nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
       # $vmconfig = Set-AzVMOperatingSystem -Windows  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest;
        $VmConfig = New-AzVMConfig  -VMName $VMname -VMSize $VMSKU | Set-AzVMOperatingSystem -Windows  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter  -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID;
       # $VmConfig = Set-AzVMOSDisk -VM $VmConfig -ManagedDiskId $OSdisk.Id -CreateOption Attach -Windows
        break}
    {$_ -eq "Linux"} {
        write-host "Creating Linux Profile"
        $NSGRule = New-AzNetworkSecurityRuleConfig -Name MyNsgRuleRDP  -Protocol Tcp  -Direction Inbound  -Priority 1000  -SourceAddressPrefix *  -SourcePortRange *  -DestinationAddressPrefix *  -DestinationPortRange 22 -Access Allow;
         # Create a network security group
        $NSG = New-AzNetworkSecurityGroup  -ResourceGroupName $Resourcegroup  -Location $Location  -Name VMtworkSecurityGroup  -SecurityRules $NSGRule;
        $VMNICname = $vmname + "-NIC"
        $VMIpConfig     = New-AzNetworkInterfaceIpConfig -Name $VMNICname -Subnet $Subnet -PublicIpAddress $vmpip 
        $nic = New-AzNetworkInterface -Name $VMNICname -ResourceGroupName $Resourcegroup -Location $Location -NetworkSecurityGroupId $NSG.Id -IpConfiguration $VMIPConfig
        $VmConfig = New-AzVMConfig  -VMName $VMname -VMSize $VMSKU | Set-AzVMOperatingSystem  -Linux  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest |  Add-AzVMNetworkInterface -Id $Nic.ID;
        #$vmconfig = Set-AzVMOperatingSystem -Linux  -ComputerName $Vmname -Credential $cred |  Set-AzVMSourceImage  -PublisherName Canonical -Offer WindowsServerUbuntuServer -Skus 14.04.2-LTS -Version latest;
        break}
    }
#VMconfig
write-host "Creating VM"
New-AZVm -ResourceGroupName $Resourcegroup -Location $location -VM $vmConfig -verbose
#setting Boot diagnostic storage account
$vm = Get-AzVM -Name $vmName  -ResourceGroupName $Resourcegroup
Set-AzVMBootDiagnostic  -VM $vm  -ResourceGroupName $Resourcegroup -StorageAccountName $storageaccountname -Enable
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup