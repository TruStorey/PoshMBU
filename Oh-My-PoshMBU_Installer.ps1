# Set Execution Policy
Write-Output "Setting Execution Policy"
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

# Check for .ssh folder in home folder, if not create one.
Write-Output "Checking for SSH keys..."
$SSHKeyPath = Test-Path ~/.ssh
if ($SSHKeyPath) {
    $SSHKeyPrv = Test-Path ~/.ssh/id_rsa
    $SSHKeyPub = Test-Path ~/.ssh/id_rsa.pub

    if ($SSHKeyPrv) {
        if ((Get-Item .~/.ssh/id_rsa).Length -gt 0) { 
            Write-Output "Private key file found."  
        } 
        else { 
            Write-Output "Private key is blank." 
        }
    }
    else {
        Write-Output "No Private Key found."
        <#
        Write-Output "No Private Key found. Attempting to copy your id_rsa from your WSL Ubuntu home directory"
        try {
            Copy-Item -Path "\\wsl$\Ubuntu-18.04\home\$env:USERNAME\.ssh\id_rsa" -Destination "~/.ssh/"        
        }
        catch {
            Write-Error "Error copying RSA private key. Either the key could not be copied or does not exist."
        }#>
    }
    if ($SSHKeyPub) {
        if ((Get-Item .~/.ssh/id_rsa.pub).Length -gt 0) { 
            Write-Output "Public key file found."  
        } 
        else { 
            Write-Output "Public key is blank." 
        }
    }
    if ($SSHPubExist) {
        Write-Output "Public Key found."
    }
    else {
        Write-Output "No Public Key found."
        <#Write-Output "No Public Key found. Attempting to copy your id_rsa.pub from your WSL Ubuntu home directory"
        try {
            Copy-Item -Path "\\wsl$\Ubuntu-18.04\home\$env:USERNAME\.ssh\id_rsa.pub" -Destination "~/.ssh/"        
        }
        catch {
            Write-Error "Error copying RSA public key. Either the key could not be copied or does not exist."
        }#>
    }
}
else {
    Write-Output "No SSH keys found.`nEither copy existing ones from \\wsl$\Ubuntu-18.04\home\$env:USERNAME\.ssh\`n   or`n run ssh-keygen to create keys. You will need to upload your public key to the identify portal."
}

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

Start-Process "pwsh.exe" -Credential $localcreds -ArgumentList "-Command Set-Service ssh-agent -StartupType Automatic" -UseNewEnvironment
Start-Process "pwsh.exe" -Credential $localcreds -ArgumentList "-Command Start-Service ssh-agent" -UseNewEnvironment

# Terminal-Icons: https://github.com/devblackops/Terminal-Icons
Install-Module -Name Terminal-Icons -Repository PSGallery -Force

# Install oh-my-posh
Write-Output "Configuring oh-my-posh"
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))

# Install PoshMBU


# Write to Profile
Write-Output "Configuring Powershell Profile"
Write-Output "`n # PSReadline Settings`nSet-PSReadLineOption -PredictionSource History" | Out-File -FilePath $PROFILE -Append
Write-Output "`n # oh-my-posh Settings`n oh-my-posh init pwsh --config C:\Users\daniel.storey\AppData\Local\oh-my-posh\themes\takuya.omp.json" | Out-File -FilePath $PROFILE -Append
Write-Output "`n # Imports`nImport-Module Terminal-Icons`nImport-Module PoshMBU" | Out-File -FilePath $PROFILE -Append

# Complete
Write-Output "PoshMBU Configuration Complete. Please reload Powershell."