param ([switch] $chrome,[switch] $firefox,[switch] $adobe,[switch] $all,[switch] $devTest,[switch] $office)
if ($all -or !$chrome -and !$firefox -and !$adobe -and !$office) { 
    $chrome = $true 
    $firefox = $true
    $adobe = $true 
    $office = $true
}

$ProgressPreference = 'SilentlyContinue'
#Intial folder and files downloads

$baseDir = [System.IO.Path]::GetTempPath() + "MNB-RMM-TOOLS"
$chromeMSI = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$adobeMSI = "https://ardownload3.adobe.com/pub/adobe/reader/win/AcrobatDC/2500120693/AcroRdrDC2500120693_en_US.exe"
$firefoxMSI = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=en-GB"
$adobeReaderReg = 'HKCU:\Software\Adobe\Acrobat Reader\DC\AVGeneral'
$adobeAcrobatReg = 'HKCU:\Software\Adobe\Adobe Acrobat\DC\AVGeneral'

$currentMachine = Get-WmiObject -Class Win32_Bios
$Serial = $currentMachine | Select-Object SerialNumber 
$Serial = $Serial -replace ".*=" -replace "}.*"
$Manufacturer = $currentMachine | Select-Object Manufacturer 
$Manufacturer = $Manufacturer -replace ".*=" -replace "}.*"


if (!(Test-Path $baseDir)) {
    mkdir $baseDir
}

if ($adobe) {
    if (!$devTest -or !(Test-Path $baseDir/AcroRdrDC.exe)) {Invoke-WebRequest -Uri $adobeMSI -OutFile "$baseDir/AcroRdrDC.exe"} 
    Start-Process -FilePath "$baseDir/AcroRdrDC.exe" -ArgumentList "/sAll /rs EULA_ACCEPT=YES" -Wait
    Write-Output("Adobe install complete.")
    

    if (!(Test-Path -LiteralPath $adobeReaderReg)) { [void] (New-Item -Path $adobeReaderReg -Force) }
    if (!(Test-Path -LiteralPath $adobeAcrobatReg)) { [void] (New-Item -Path $adobeAcrobatReg -Force) }
    Set-ItemProperty -Path $adobeReaderReg -Name bEnableAV2 -Value 0 -Type DWord
    Set-ItemProperty -Path $adobeAcrobatReg -Name bEnableAV2 -Value 0 -Type DWord
}

if ($chrome) {
    if (!$devTest -or !(Test-Path $baseDir/ChromeInstaller.msi)) {Invoke-WebRequest -Uri $chromeMSI -OutFile "$baseDir/ChromeInstaller.msi"}
    Start-Process -FilePath "$baseDir/ChromeInstaller.msi" -ArgumentList "/qn" -Wait
    Write-Output("Chrome install complete.")
}

if ($firefox) {
    if (!$devTest -or !(Test-Path $baseDir/FirefoxInstaller.msi)) {Invoke-WebRequest -Uri $firefoxMSI -OutFile "$baseDir/FirefoxInstaller.msi"}
    Start-Process -FilePath "$baseDir/FirefoxInstaller.msi" -ArgumentList "/quiet" -Wait
    Write-Output("Firefox install complete.")
}

if ($office) {
    if (!(Test-Path $baseDir/Office)) { mkdir $baseDir/Office }
    if (!$devTest -or !(Test-Path $baseDir/Office/OfficeSetup.exe)) { Invoke-WebRequest -Uri "https://github.com/Evlie/LGPO-script/raw/refs/heads/main/Office/setup.exe" -OutFile "$baseDir/Office/OfficeSetup.exe" }
    if (Test-Path "$baseDir/Office/Default_apps_for_business.xml") { Remove-Item -Path $baseDir/Office/Default_apps_for_business.xml}
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Evlie/LGPO-script/refs/heads/main/Office/Default_apps_for_business.xml" -OutFile "$baseDir/Office/Default_apps_for_business.xml"
    
    Start-Process -FilePath "$baseDir/Office/OfficeSetup.exe" -ArgumentList "/download $baseDir/Office/Default_apps_for_business.xml" -Wait
    Start-Process -FilePath "$baseDir/Office/OfficeSetup.exe" -ArgumentList "/configure $baseDir/Office/Default_apps_for_business.xml" -Wait

}
