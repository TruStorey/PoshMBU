### Execution Policy
Write-Output "Setting Execution Policy"
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

### Check for SSH Keys
Write-Output "Checking SSH key files exist"
$SSHPrvExist = Test-Path ~/.ssh/id_rsa
$SSHPubExist = Test-Path ~/.ssh/id_rsa.pub
if ($SSHPrvExist) {
    Write-Output "Private Key file found"
}2
else {
    Write-Output "No Private Key found. Copy your id_rsa to ~/.ssh/id_rsa"
}
if ($SSHPubExist) {
    Write-Output "Public Key found"
}
else {
    Write-Output "No Public Key found. Copy your id_rsa.pub to ~/.ssh/id_rsa.pub"
}

### Configure Powershell
Write-Output "Configuring SSH and PSReadline"
Set-Service ssh-agent -StartupType Automatic #Might only work as admin
Set-PSReadLineOption -PredictionSource History

### Install Modules
# Rax
# ModuleManager: https://rax.io/MMInstall
[System.Net.ServicePointManager]::SecurityProtocol = @(
    [System.Net.SecurityProtocolType]::Tls;,
    [System.Net.SecurityProtocolType]::Tls12;
)
& ([scriptblock]::Create((Invoke-WebRequest "https://rax.io/MMscript").Content))

# PoshCore and RaxUtilities
Install-RaxModule PoshCore
Install-RaxModule RaxUtilities

# PoshMBU
New-Item -Path "$home\Documents\WindowsPowerShell\Modules\" -Name PoshMBU -ItemType Directory
New-Item -Path "$home\Documents\PowerShell\Modules\" -Name PoshMBU -ItemType Directory
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TruStorey/PoshMBU/master/PoshMBU.psm1?token=GHSAT0AAAAAABUADYQ4Q2DHZLA7HZJLZBSIYT3TPUA" -OutFile "$home\Documents\WindowsPowerShell\Modules\PoshMBU\PoshMBU.psm1"
Copy-Item -Path "$home\Documents\WindowsPowerShell\Modules\PoshMBU\PoshMBU.psm1" -Destination "$home\Documents\PowerShell\Modules\PoshMBU\PoshMBU.psm1"

Import-Module PoshMBU