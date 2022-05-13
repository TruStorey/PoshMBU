### Execution Policy
Write-Output "Setting Execution Policy"
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

### Check for SSH Keys
Write-Output "Checking SSH key files exist"
#TEST IF FOLDER EXISTS FIRST
$SSHPrvExist = Test-Path ~/.ssh/id_rsa
$SSHPubExist = Test-Path ~/.ssh/id_rsa.pub
if ($SSHPrvExist) {
    Write-Output "Private Key file found"
}2
else {
    Write-Output "No Private Key found. Attempting to copy your id_rsa from your WSL Ubuntu home directory"
    try {
        Copy-Item -Path "\\wsl$\Ubuntu-18.04\home\$env:USERNAME\.ssh\id_rsa" -Destination "~/.ssh/"        
    }
    catch {
        Write-Error "Error copying RSA private key. Either the key could not be copied or does not exist."
    }
}
if ($SSHPubExist) {
    Write-Output "Public Key found"
}
else {
    Write-Output "No Public Key found. Attempting to copy your id_rsa.pub from your WSL Ubuntu home directory"
    try {
        Copy-Item -Path "\\wsl$\Ubuntu-18.04\home\$env:USERNAME\.ssh\id_rsa.pub" -Destination "~/.ssh/"        
    }
    catch {
        Write-Error "Error copying RSA public key. Either the key could not be copied or does not exist."
    }
}

### Configure Powershell
Write-Output "Configuring SSH and PSReadline"
Set-Service ssh-agent -StartupType Automatic #Might only work as admin
Start-Service ssh-agent
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