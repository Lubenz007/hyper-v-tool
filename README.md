# hyper-v-tool
My tool to create vm's in my lab

Utilizing a standalone Hyper-V server and generating VMs from a golden image might be considered an older approach, but it's one I personally prefer. Over the years, I've diligently maintained a tool for crafting VMs on my Hyper-V host within the lab environment. I employ SSH to connect to the Hyper-V host and initiate the VM creation process. This tool provides a streamlined menu system that automatically configures the VM, allowing me to promptly begin using it.
* All config is done in the vm_menu.ps1
 
#working folder
$mypath = Get-Location
$global:StartupFolder = $mypath.Path

# You can find the oscdimg.exe in the Windows 11 22h2 ADK: 
# https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install 
# Kit "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\arm64\Oscdimg"
$global:oscdimgPath = "$global:StartupFolder\tools\oscdimg.exe"

#Template location
$global:template = "$global:StartupFolder\template"

#template vhd name / windows is sysprep / Ubuntu cloud-init / modify for your template.
$global:2022core = "W2022C.vhdx"
$global:2022stand = "W2022S_OS.vhdx"
$global:2022data = "W2022D_OS.vhdx"
$global:Ubuntu = "Ubuntu_OS.vhd"
  
![image](https://github.com/Lubenz007/hyper-v-tool/assets/116028026/1e961bfd-aa70-41c3-96dd-6740f175d03b)
![image](https://github.com/Lubenz007/hyper-v-tool/assets/116028026/24f16f37-738a-4a17-a990-238896e9bcb3)
![image](https://github.com/Lubenz007/hyper-v-tool/assets/116028026/ac87298b-dd9d-4d1c-8d06-3db92c6105bf)



