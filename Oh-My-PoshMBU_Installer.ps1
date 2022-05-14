### Execution Policy
Write-Output "Setting Execution Policy"
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

### Check for SSH Keys
Write-Output "Checking SSH key files exist"

# Check for .ssh folder in home folder, if not create one.
$SSHKeyPath = Test-Path ~/.ssh/id_rsa
if ($SSHKeyPath) {
    continue
}
else {
    New-Item -Path ~/.ssh-test -ItemType Directory
}

$SSHKeyPrv = Test-Path ~/.ssh/id_rsa
$SSHKeyPub = Test-Path ~/.ssh/id_rsa.pub

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

### Configure Powershell PSReadline
Write-Output "Configuring PSReadline"
Set-Service ssh-agent -StartupType Automatic #Might only work as admin
Start-Service ssh-agent
Set-PSReadLineOption -PredictionSource History

### Install Modules
# Terminal-Icons: https://github.com/devblackops/Terminal-Icons
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# Oh My Posh: https://ohmyposh.dev/docs/windows
#Install-Module oh-my-posh -Scope CurrentUser

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

### Configure Powershell OpenSSH
Write-Output "Configuring OpenSSH"
# Get local admin pass and run the following commands eleveated.
$localadminpass = ConvertTo-SecureString -AsPlainText -String (Get-RackerAdminPassword).Password[0]
$localadminuser = "$env:COMPUTERNAME\rackadm2013"

$localcreds = New-Object System.Management.Automation.PSCredential -ArgumentList $localadminuser, $localadminpass

Start-Process "pwsh.exe" -Credential $localcreds -ArgumentList "-Command Set-Service ssh-agent -StartupType Automatic"

Set-Service ssh-agent -StartupType Automatic #Might only work as admin
Start-Service ssh-agent
Set-PSReadLineOption -PredictionSource History

# PoshMBU
Install-Module PoshMBU

# Copy stuff to Profile. 

#Create a command that just loads the login thing.