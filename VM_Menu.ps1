#Benedikt Egilsson
$host.ui.RawUI.WindowTitle = "Bensi Virtual Tool $PSScriptRoot "

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

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
$global:2022core = "W2022C_OS.vhdx"
$global:2022stand = "W2022S_OS.vhdx"
$global:2022data = "W2022D_OS.vhdx"
$global:Ubuntu = "Ubuntu_OS.vhd"
$global:Centos7 = "Centos7_OS.vhdx"
$global:Debian = "Debian_OS.vhdx"
        
Foreach ($i in get-childitem $global:StartupFolder\modules\B*.psm1)
{
	import-module $i
}

    
Function Show-Menu {
    	
	Param (
		[Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter your menu text")]
		[ValidateNotNullOrEmpty()]
		[string]$Menu,
		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[string]$Title = "Menu",
		[switch]$ClearScreen
	)
	
	if ($ClearScreen) { Clear-Host }
	#build the menu prompt
	$menuPrompt = $title
	#add a return
	$menuprompt += "`n"
	#add an underline
	$menuprompt += "-" * $title.Length
	$menuprompt += "`n"
	#add the menu
	$menuPrompt += $menu
	
	Read-Host -Prompt $menuprompt
}


Function MainMenu {
	$menu = @"

1: Download VHD's

2: Create VM's

3: About

Q: Quit

-----

Select a task by number or Q to quit
"@
	
	Do {
		Switch (Show-Menu $menu "Bensa Virtual Tool" -clear) {
			"1" { DOWN_VHD }
			"2" { Create_VM }
			"3" { About }
			"Q" {
				Clear-Host
				Write-output "Have a nice day"
				Start-Sleep 2
				Remove-Module BGE*
				exit
			}
			Default {
				Write-Warning "Invalid Choice. Try again."
				Start-Sleep -milliseconds 750
			}
		}
	} While ($True)
}

Function Create_VM {
	$menu = @"

1: Create New Empty VM

2: Create Windows Vm From Template

3: Create Linux Vm From  Template

B: Back

-----

Select a task by number or B to go back
"@
	Do {
		clear-host
		Switch (Show-Menu $menu "Management Menu" -clear) {
			"1" { Empty_Vm }
			"2" { BGE_Vm_Windows }
			"3" { BGE_Vm_linux }
			"B" { MainMenu }
			Default { Write-Warning "Invalid Choice. Try again."; Start-Sleep -milliseconds 750 }
		}
	} While ($True)
}

Function DOWN_VHD {
	$menu = @"

1: Download 2022 Datacenter Eval from Mirosoft.com

2: Download VHD's from Ubuntu.com

3: Download VHD's from Centos.org

B: Back

-----

Select a task by number or B to go back
"@
	Do {
		Switch (Show-Menu $menu "Vhd files are stored in template folder" -clear) {
			"1" { Download_vm_Windows }
			"2" { vm_Ubuntu }
			"3" { vm_Centos }
			"B" { MainMenu }
			Default { Write-Warning "Invalid Choice. Try again."; Start-Sleep -milliseconds 750 }
		}
	} While ($True)
}
Function About {
	
	Write-Output "
    Benedikt G. Egilsson put to gether with help from the internet
    Tested in lab environments, Use at your own risk."
	Read-Host "Press Enter to return to menu"
}


MainMenu