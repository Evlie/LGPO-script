

#Intial folder and files downloads
$baseDir = [System.IO.Path]::GetTempPath() + "MNB-RMM-TOOLS"

if (!(Test-Path $baseDir)) {
    mkdir $baseDir
}
if (!(Test-Path $baseDir/Policies)) {
    mkdir $baseDir/Policies
}

Invoke-WebRequest -Uri "https://github.com/Evlie/LGPO-script/raw/refs/heads/main/LGPO.exe" -OutFile "$baseDir/LGPO.exe"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Evlie/LGPO-script/refs/heads/main/Policies/Remove_Target_Update_Server.txt" -OutFile "$baseDir/Policies/Remove_Target_Update_Server.scp"



#Begin script execution 
& "$baseDir/LGPO.exe" /t $baseDir/Policies/Remove_Target_Update_Server.scp
gpupdate /force
clear
Remove-Item $baseDir -Recurse -Force
