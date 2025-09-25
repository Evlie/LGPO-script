param ([switch] $chrome,[switch] $firefox,[switch] $adobe,[switch] $office,[switch] $all,[switch] $removeAV,[switch] $devTest)
if ($all -or !$chrome -and !$firefox -and !$adobe -and !$office) { 
    $chrome = $true 
    $firefox = $true
    $adobe = $true 
    $office = $true
}
$ProgressPreference = 'SilentlyContinue'

If(-not(Get-InstalledModule -Name Microsoft.PowerShell.ThreadJob -ErrorAction silentlycontinue)){
    Install-Module -Name Microsoft.PowerShell.ThreadJob -Confirm:$False -force
}

#Intialize folders and file downloads

$baseDir = [System.IO.Path]::GetTempPath() + "MNB-RMM-TOOLS"
$adobeReaderReg = 'HKCU:\Software\Adobe\Acrobat Reader\DC\AVGeneral'
$adobeAcrobatReg = 'HKCU:\Software\Adobe\Adobe Acrobat\DC\AVGeneral'

$currentMachine = Get-WmiObject -Class Win32_Bios
$Serial = $currentMachine | Select-Object SerialNumber 
$Serial = $Serial -replace ".*=" -replace "}.*"
$Manufacturer = $currentMachine | Select-Object Manufacturer 
$Manufacturer = $Manufacturer -replace ".*=" -replace "}.*"

$downloads =@(
    @{Uri = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"; OutFile = "$baseDir\ChromeInstaller.msi"}
    @{Uri = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-GB"; OutFile = "$baseDir\FirefoxInstaller.msi"}
    @{Uri = "https://ardownload3.adobe.com/pub/adobe/reader/win/AcrobatDC/2500120693/AcroRdrDC2500120693_en_US.exe"; OutFile = "$baseDir\AcroRdrDC.exe"}
    @{Uri = "https://github.com/Evlie/LGPO-script/raw/refs/heads/main/Office/setup.exe"; OutFile = "$baseDir\Office\OfficeSetup.exe"}
    @{Uri = "https://raw.githubusercontent.com/Evlie/LGPO-script/refs/heads/main/Office/Default_apps_for_business.xml"; OutFile = "$baseDir\Office\Default_apps_for_business.xml"}
)

if (!$chrome) {$downloads[0] = $null}
if (!$firefox) {$downloads[1] = $null}
if (!$adobe) {$downloads[2] = $null}
if (!$office) {$downloads[3] = $null, $downloads[4] = $null}


#Core script

if (!(Test-Path "$baseDir") -or $office) {
    if (!(Test-Path "$baseDir")) {mkdir "$baseDir"}
    if ($office -and !(Test-Path "$baseDir/Office")){
        mkdir "$baseDir/Office"
    }
}

$jobs = @()
foreach ($file in $downloads) {
    $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
        $params = $Using:file
        Invoke-WebRequest @params
    }
}

Write-Host "Downloads started..."
Wait-Job -Job $jobs

foreach ($job in $jobs) {
    Receive-Job -Job $job
}


if ($adobe) {
    Start-Process -FilePath "$baseDir/AcroRdrDC.exe" -ArgumentList "/sAll /rs EULA_ACCEPT=YES" -Wait
    Write-Output("Adobe install complete.")

    if (!(Test-Path -LiteralPath $adobeReaderReg)) { [void] (New-Item -Path $adobeReaderReg -Force) }
    if (!(Test-Path -LiteralPath $adobeAcrobatReg)) { [void] (New-Item -Path $adobeAcrobatReg -Force) }
    Set-ItemProperty -Path $adobeReaderReg -Name bEnableAV2 -Value 0 -Type DWord
    Set-ItemProperty -Path $adobeAcrobatReg -Name bEnableAV2 -Value 0 -Type DWord
}

if ($chrome) {
    Start-Process -FilePath "$baseDir/ChromeInstaller.msi" -ArgumentList "/qn" -Wait
    Write-Output("Chrome install complete.")
}

if ($firefox) {
    Start-Process -FilePath "$baseDir/FirefoxInstaller.msi" -ArgumentList "/quiet" -Wait
    Write-Output("Firefox install complete.")
}

if ($office) {
    Start-Process -FilePath "$baseDir/Office/OfficeSetup.exe" -ArgumentList "/download "$baseDir/Office/Default_apps_for_business.xml"" -Wait
    Start-Process -FilePath "$baseDir/Office/OfficeSetup.exe" -ArgumentList "/configure "$baseDir/Office/Default_apps_for_business.xml"" -Wait

    $source = "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/"
    $destination = ([Environment]::GetFolderPath("Desktop"))
    $filteredFiles = @("Word.*", "Publisher.*","PowerPoint.*","Outlook (classic).*","Excel.*","Access.*")
    
    ForEach ($file in $filteredFiles) {
        Copy-Item -Path "$source/$file" -Destination "$destination" -Force
    }
    Write-Output("Office install complete.")
}
