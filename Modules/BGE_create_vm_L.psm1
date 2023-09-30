function BGE_create_vm_L {
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$name,

        [Parameter(Mandatory = $True, Position = 2)]
        [string]$CpuCount,
    
        [Parameter(Mandatory = $True, Position = 3)]
        [string]$RAM,
   
        [Parameter(Mandatory = $True, Position = 4)]
        [string]$net,
    
        [Parameter(Mandatory = $True, Position = 5)]
        [string]$IpAddress,

        [Parameter(Mandatory = $True, Position = 6)]
        [string]$subnetmask,
        
        [Parameter(Mandatory = $True, Position = 7)]
        [string]$DefaultGW,
    
        [Parameter(Mandatory = $True, Position = 8)]
        [string]$DNSServer,
    
        [Parameter(Mandatory = $True, Position = 9)]
        [string]$DNSDomain,
    
        [Parameter(Mandatory = $True, Position = 10)]
        [string]$DHCP,

        [Parameter(Mandatory = $True, Position = 11)]
        [string]$sshkey,

        [Parameter(Mandatory = $True, Position = 12)]
        [string]$linuxuser
  
    )
    
    #get the local path for virtual machines
    $dPath = Get-VMHost | Select-Object VirtualMachinePath -ExpandProperty VirtualMachinePath

    #Where's the VM Default location? You can also specify it manually
    $path = "$Dpath$name\"
    #$VHDPath = $Path + $Name + "\" + $Name + ".vhd"
    $VHDPath = $Path + $Name + ".vhd"

    #random generator
    $random = (1000..9999) | Get-Random -Count 1

    #set static macaddress for vm
    $firstbytes = "00-15-5D"
    $randommac = [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF)), 0, 3)
    $Mac = $firstbytes + "-" + $randommac
    #replace - for : in mac.
    $Mac = $Mac.Replace('-', ':')

    #Cloud-init Config


$metadata = @"
instance-id: $($name+$random)
local-hostname: $($name)
"@

$userdata = @"
#cloud-config
 
# configure interaction with ssh server
ssh_genkeytypes: ['ed25519', 'rsa']

# Users
chpasswd: { expire: True }
password: Passw0rd
ssh_authorized_keys:
        - $sshkey
ssh_pwauth: True

users:
    - default
    - name: $linuxuser
      groups: ['wheel']
      shell: /bin/bash
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh-authorized-keys:
        - $sshkey
 
# Configure where output will go
output:
  all: ">> /var/log/cloud-init.log"
        
# Install my public ssh key to the first user-defined user configured

# update os
package_upgrade: true
package_update: true
package_reboot_if_required: true

packages:
  - linux-virtual
  - linux-cloud-tools-virtual
  - linux-tools-virtual

# Disable cloud-inint
runcmd:
  - touch /etc/cloud/cloud-init.disabled

power_state:
 delay: "+1"
 mode: poweroff
 message: Bye Bye
 timeout: 30
 condition: True
"@

    #make meta data files for cloud-init
    Set-Content "$($global:StartupFolder)\data\meta-data" ([byte[]][char[]] "$metadata") -AsByteStream
    Set-Content "$($global:StartupFolder)\data\user-data" ([byte[]][char[]] "$userdata") -AsByteStream
  
    #Set the VM Domain access NIC name , i dont need this,,... will I
    $NetworkAdapterName = "Network Adapter"
    if ($NetworkAdapterName -eq "") { $NetworkAdapterName = "Ethernet" } ; if ($NULL -eq $NetworkAdapterName) { $NetworkAdapterName = "Ethernet" }
   
    #Create the VM
    New-VM -Name $Name -Path $Path -MemoryStartupBytes $RAM -Generation 1 -NoVHD
    Set-VMMemory -VMName $name -DynamicMemoryEnabled $true -MaximumBytes $RAM -MinimumBytes $RAM
    
    #Remove any auto generated adapters and add new ones with correct names for Consistent Device Naming and vlan
    Get-VMNetworkAdapter -VMName $Name | Remove-VMNetworkAdapter
    Add-VMNetworkAdapter -VMName $Name -SwitchName $net -Name $NetworkAdapterName -DeviceNaming On
    Set-VMNetworkAdapter -VMName $name -StaticMacAddress $Mac
    Set-VMNetworkAdapterVlan -VMName $name -Access -VlanId $global:vlan

    # Set FW type to enable secureboot version 2 
    #Set-VMFirmware -VMName $name -EnableSecureBoot on -SecureBootTemplate MicrosoftUEFICertificateAuthority
 
    #Copy the template and add the disk on the VM.
    $totalTimes = 1
    $i = 0
    for ($i = 0; $i -lt $totalTimes; $i++) {
        Write-Progress -Activity "Copy $global:TemplateLocation to $VHDPath"
        copy-Item -Path $global:TemplateLocation -Destination $VHDPath
        Write-Progress -Activity "Copy $global:TemplateLocation to $VHDPath" -Status "Ready" -Completed
        Start-Sleep 1
    }
   
    #Set cpu account    
    Set-VM -Name $Name -ProcessorCount $CpuCount -AutomaticStartAction Start -AutomaticStopAction ShutDown -AutomaticStartDelay 5 

    #Add-VMHardDiskDrive -VMName $Name -ControllerType SCSI -Path $VHDPath
    Add-VMHardDiskDrive -VMName $Name -ControllerType IDE -Path $VHDPath
 
    #Set first boot device to the disk we attached
    #$Drive = Get-VMHardDiskDrive -VMName $Name | Where-Object { $_.Path -eq "$VHDPath" }
    #Get-VMFirmware -VMName $Name | Set-VMFirmware -FirstBootDevice $Drive

    #disable automatic check point
    get-vm -Name $name | Set-VM -AutomaticCheckpointsEnabled $false

    #Create ISO Cloud-init
    $metaDataIso = "$($Path)metadata.iso"
    & $global:oscdimgPath "$($global:StartupFolder)\data\" $metaDataIso -j2 -lcidata

    #mount iso file for first boot
    Add-VMDvdDrive -VMName $name -Path $metaDataIso

    #Remove files metadata
    Remove-Item -Path "$($global:StartupFolder)\data\*data" -Force

    #Fire up the VM
    Start-VM $Name
  
    do {
        $VM1 = get-vm -Name $Name
        Write-Progress -Activity "Customize VM and Waiting for the VM to shutdown" 
    } until ($Null -eq $VM1.Heartbeat)
    

    #Dismount DVD ISO file
    Get-VMDvdDrive -VMName $name | Remove-VMDvdDrive

    #Remove ISO file
    remove-Item -Path $metaDataIso -Force

    #Fire up the VM
    start-vm $Name

    #Wait for vm getting ip
    do {
        $ipadd = get-vm -name $name | get-VMNetworkAdapter
        Write-Progress -Activity "Waiting for VM Ipadress" 
    } until ($true -eq $ipadd.IpAddresses[0])
    
    $output = $ipadd.IpAddresses[0]

    #Add the vm to HA cluster
    $cmdName = "Get-cluster"
    if (Get-Command $cmdName -errorAction SilentlyContinue) {
        $cluster = Get-Cluster
        $hostname = $env:computername
        Get-VM $name -ComputerName $hostname | Add-VMToCluster -Cluster (Get-Cluster $cluster) -errorAction SilentlyContinue | out-null 
    }

    Read-Host "Done creating Vm $name With user $linuxuser use sshkey / Default Admin username: Ubuntu:ubuntu # CentOS:centos Password:passw0rd Ipaddress $output Copy info and Press Enter to Continue"
}