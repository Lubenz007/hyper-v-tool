function Download_vm_Windows {
#Download VHD file from Microsoft Evaluation Center Windows 2022 Server Datacenter
$url = "https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022"
$content = Invoke-WebRequest -Uri $url -ErrorAction Stop
$downloadlink = $content.links | Where-Object { `
        $_.'aria-label' -match 'Download' `
        -and $_.'aria-label' -match 'VHD'
}
#Create object with VHD download link
$Download = [PSCustomObject]@{
    Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
    Tag    = $DownloadLink.'data-bi-tags'.Split('&')[3].split(';')[1]
    Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
    Link   = $DownloadLink.href
}
#Download VHD file
if(Test-Path $global:template\W2022D_OS.vhd){
    $response = Read-Host "The file W2022D_OS.vhd already exists, remove and get new? (Y/N)"
    if($response -eq "Y"){
        Write-Host "File Removed and download new"
        Remove-Item $global:template\W2022D_OS.vhd
        $VHDFile = "$global:template\W2022D_OS.vhd"
        Invoke-WebRequest -Uri $Download.Link -OutFile $VHDFile
    } elseif($response -eq "N"){
        Write-Host "Not overwriting file 'W2022D_OS.vhd'."
    } else {
        Write-Host "Invalid response. Please enter Y or N."
    }
} else {
    $VHDFile = "$global:template\W2022D_OS.vhd"
    Invoke-WebRequest -Uri $Download.Link -OutFile $VHDFile
}
Read-Host "Nothing to do here, press enter to continue"
}
