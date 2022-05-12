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
    Write-Output "No Private Key found. Copy your id_rsa. is copied to ~/.ssh/id_rsa"
}
if ($SSHPubExist) {
    Write-Output "Public Key found"
}
else {
    Write-Output "No Public Key found. Copy your id_rsa is copied to ~/.ssh/id_rsa.pub"
}

### Configure Powershell
Write-Output "Configuring SSH and PSReadline"
Set-Service ssh-agent -StartupType Automatic #Might only work as admin
Set-PSReadLineOption -PredictionSource History

### Install Modules
# Terminal-Icons: https://github.com/devblackops/Terminal-Icons
Install-Module -Name Terminal-Icons -Repository PSGallery -Force 

# Oh My Posh: https://ohmyposh.dev/docs/windows
Install-Module oh-my-posh -Scope CurrentUser

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
Install-Module PoshMBU