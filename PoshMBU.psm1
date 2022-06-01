<#
 .Synopsis
  MBU Engineering Module for PoshCore and RaxUtilities.

 .Description
  Powershell cmdlets to interact with Core focused on MBU Engineering.

 .Parameter Device
  This is a wild card search e.g. "CS0901", "CS0404DD", "CS0802DM02". NOTE: Core hostnames are case sensitive, there is logic built in to attemtp lowercase and uppsercase versions of the name you specify. 

 .Example
   # Shows a list of all devices with CS0404 in the Hostname and their Core Status.
   Get-mbuDevice CS0404
   g CS0404

 .Example
   # Connect to a Linux device using SSH
   Connect-

#>

#Requires -Modules ModuleManager, PoshCore, RaxUtilities

# Used to convert provided hostname to device number
# Need to add logic to search for both as sometimes both are returned!
function Convert-CoreDeviceNameToNumber {
    param (
        [Parameter(Position = 0, Mandatory)]$Device,
        [Parameter(Mandatory)][int]$Account
    )
    # Test if Hostname or Device Number was passed in parameters.
    if ($Device.GetType().Name -eq 'Int32') {
        $mbuDevices = $Device
    }
    elseif ($Device.GetType().Name -eq 'String') {
        $mbuDevices = (Find-CoreComputerByHostname -Account $Account -Hostname $Device | Select-Object number).number
        if ($mbuDevices) {
            $mbuDevices = $mbuDevices
        }
        # Logic to try upper case and lower case names 
        else {
            $DeviceToUpper = $Device.ToUpper()
            $mbuDevices = (Find-CoreComputerByHostname -Account $Account -Hostname $DeviceToUpper | Select-Object number).number
            if ($mbuDevices) {
                $mbuDevices = $mbuDevices
            }
            else {
                $DeviceToLower = $Device.ToLower()
                $mbuDevices = (Find-CoreComputerByHostname -Account $Account -Hostname $DeviceToLower | Select-Object number).number
            }
        }
    }
    if ($mbuDevices) {
        Write-Output $mbuDevices
    }
    else {
        Write-Warning "Could not find a Core device with name '$DeviceToUpper' or '$DeviceToLower'. `n`rPROTIP: You either fat fingered it, or the device name in Core is written in CamelCase.`n"
        break
    }    
}

function Get-mbuDevice {
    param (
        [Parameter(Position = 0, Mandatory)]$Device,
        [Parameter()][switch]$IPs,
        [Parameter()][switch]$SwitchPorts,
        [Parameter()][switch]$DRAC,
        [Parameter()][switch]$Credentials,
        [Parameter()][switch]$Virt,
        [Parameter()][switch]$vCenter,
        [Parameter()][switch]$vPortal,
        [Parameter()][switch]$OpenCore,
        [Parameter()][int]$Account = 27928,
        [Parameter()][switch]$TypeRackPass,
        [Parameter()][int]$TypeTimer = 5,
        #[Parameter(ParameterSetName = 'ByStatus')]
        #[ValidateSet('DFW3' ,'ORD1' ,'IAD3' ,'IAD4' ,'LON3' ,'LON5' ,'LON6' ,'LON7' ,'FRA1' ,'FRA30' ,'HKG2' ,'HKG5' ,'SYD2' ,'SYD4' ,'SIN2' ,'SIN30' ,'SIN80' ,'NYC2' ,'SJC2' ,'MCI1' ,'SHA2',IgnoreCase=$true)][string]$DC, 
        [Parameter(ParameterSetName = 'ByStatus')][switch]$Inactive
    )
    
    begin {
        $mbuDevices = (Convert-CoreDeviceNameToNumber -Device $Device -Account $Account)
    }

    process {
        if ($Inactive) { 
            $Results = Find-CoreComputer -Computers @($mbuDevices) | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='Status';Expression='status_name'}
            } 
        elseif ($IPs) {
            $Results = Get-NetworkInformation -Device $mbuDevices | Select-Object Device,@{Name='Hostname';Expression='DeviceName'},@{Name='Public IP';Expression='PublicIp'},@{Name='ServiceNet IP';Expression='ServiceNetIp'},AggExZone
        }
        elseif ($SwitchPorts) {
            $Results = Get-NetworkSwitchPort -Device $mbuDevices | Select-Object Device, Type, Switch, Port, Link, Vlan, Mode, MacAddresses, Speed, Duplex, Uptime
        }
        elseif ($DRAC) {
            $Results = Find-CoreComputer -Computers @($mbuDevices) -Attributes Drac | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='DRAC IP';Expression='drac_ips'},@{Name='DRAC User';Expression='drac_usernames'},@{Name='DRAC Password';Expression='drac_passwords'}
        }       
        elseif ($Credentials) {
            $Results = Find-CoreComputer -Computers @($mbuDevices) -Attributes Password | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='Rack Pass';Expression='rack_password'},@{Name='Admin Pass';Expression='admin_password'}
        }
        elseif ($Virt) {
            $Results = Get-VmInformation -Device $mbuDevices | Select-Object Device,@{Name='Hostname';Expression='DeviceName'},DC,Networks,PowerState,Hypervisor,HypervisorClusterName,VCenter
        }
        elseif ($vCenter) {
            Open-VCenter -Device $mbuDevices
        }
        elseif ($vPortal) {
            $hypDevice = (Get-VmInformation -Device $mbuDevices | Select-Object Hypervisor).Hypervisor.Split("-")[0]
            $PortalURL = "https://racker.my.rackspace.com/portal/rs/$SearchAccount/virtualization/index#!/detail/$mbuDevices/$hypDevice"
            Start-Process $PortalURL
        }
        elseif ($OpenCore) {
            Show-CoreComputer -Computer $mbuDevices
        }
        elseif ($TypeRackPass) {
            $RackPassword = (Find-CoreComputer -Computers @($mbuDevices) -Attributes Password).rack_password
            if ($RackPassword) {
                $Typer = New-Object -ComObject wscript.shell;
                Start-Sleep $TypeTimer
                $Typer.SendKeys($RackPassword)
            }
        }
        else { 
            $Results = Find-CoreComputer -Computers @($mbuDevices) | Where-Object {$_.status_name -match 'Online/Complete'} | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='Status';Expression='status_name'}
        }
    }

    end {
        Write-Output $Results
    }
}

function Connect-mbuDevice {
    param (
        [Parameter(Position = 0, Mandatory)]$Device,
        [Parameter()][ValidateSet('ORD1','LON5',IgnoreCase=$true)][string]$Gateway="LON5",
        [Parameter()][switch]$LoginAsRack,
        [Parameter()][switch]$Isilon,
        [Parameter()][int]$Account = 27928,
        [Parameter(ParameterSetName = 'ByStatus')][switch]$Inactive
    )

    begin {
        $mbuDevices = Convert-CoreDeviceNameToNumber -Device $Device -Account $Account

        # Convert Device name to Upper case for pretty output
        $UpCaseDevice = $Device.ToUpper()
        $DeviceHostname = (Find-CoreComputer -Computers @($mbuDevices) | Select-Object name).name
        $DevOSType = (Find-CoreComputer -Computers @($mbuDevices) -Attributes Os | Select-Object os_type).os_type
        $DeviceUser = $env:USERNAME

        # Gateway Logic
        if ($Gateway -eq 'LON5') {
            $mbuGW = 'mbu.lon5.gateway.rackspace.com'
        }
        else {
            $mbuGW = 'mbu.ord1.gateway.rackspace.com'
        }
    }

    process {
        if ($LoginAsRack) {
            $DeviceUser = 'rack'
            $RackPass = ConvertTo-SecureString -AsPlainText -Force (Get-mbuDevice $mbuDevices -ShowCreds)."Rack Pass"            
            }
        else {
            $DeviceUser = $env:USERNAME
        }
        if ($DevOSType -like "*Windows"){
            Write-Output "`nConnecting to $mbuDevices ($UpCaseDevice) using RoyalTS Application default settings`r`n"
            if ($LoginAsRack) {
            Invoke-Command -ScriptBlock {& cmd /c "C:\Program Files (x86)\Royal TS V5\RoyalTS.exe" /protocol:rdp /using:uri /uri:$DeviceHostname /username:$DeviceUser /password:$RackPass}
            }
            else {
            Invoke-Command -ScriptBlock {& cmd /c "C:\Program Files (x86)\Royal TS V5\RoyalTS.exe" /protocol:rdp /using:uri /uri:$DeviceHostname}
            }
        }
        elseif ($DevOSType -like "*Linux"){
            Write-Output "`nConnecting to $mbuDevices ($UpCaseDevice) as user '$DeviceUser' via the $Gateway MBU gateway `r`n"
            Invoke-Command -Script { ssh -A gu=$env:USERNAME@$DeviceUser@$DeviceHostname@$mbuGW }
        }
        elseif ($Isilon) {
            $IsilonRootPass = ConvertTo-SecureString -AsPlainText -String (Get-PWSafe $Device -LibraryRoot).Password
            Set-Clipboard -Value (ConvertFrom-SecureString -AsPlainText $IsilonRootPass)
            Invoke-Command -Script { ssh -A gu=$env:USERNAME@root@$Device.storage.rackspace.com@$mbuGW }
        }
        else {
            Write-Error -Message "Not device type in Core, unable to identify how to logon"
        }
    }

    end {
        continue
    }
}

function Start-AsLocalAdmin {
    param (
        [Parameter(Position = 0)][string]$Command,
        [Parameter()][switch]$Browse  
    )

    begin {
        #Set local credentials
        $localpwcount = (Get-RackerAdminPassword).Password.Count
        if ($localpwcount -gt 1) {
            $localpass = ConvertTo-SecureString -AsPlainText -String (Get-RackerAdminPassword).Password[0]
        }
        else {
            $localpass = ConvertTo-SecureString -AsPlainText -String (Get-RackerAdminPassword).Password
        }
        $localuser = "$env:COMPUTERNAME\rackadm2013"
        $localcreds = New-Object System.Management.Automation.PSCredential -ArgumentList $localuser, $localpass
    }

    process {
        if ($Browse) {
            #Browsing file
            Add-Type -AssemblyName System.Windows.Forms
            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
            $FileBrowser.filter = "Executable (*.exe)| *.exe"
            [void]$FileBrowser.ShowDialog()
            $BrowsedCommand = $FileBrowser.FileName
            Start-Process "pwsh.exe" -Credential $localcreds -ArgumentList "-Command Start-Process '$BrowsedCommand'" -UseNewEnvironment
        }
        else {
            Start-Process "pwsh.exe" -Credential $localcreds -ArgumentList "-Command Start-Process '$Command'" -UseNewEnvironment
        }
    }

    end {
    }
}
function Get-PWSafe {
    param (
        [Parameter(Position = 0)]$CredName,
        [Parameter()][switch]$Maglibs,
        [Parameter()][switch]$LibraryRoot,
        [Parameter()][switch]$LibraryAdmin,
        [Parameter()][switch]$QC,
        [Parameter(ParameterSetName = 'ByProject')][ValidateSet('MBU Engineering', 'MBU Engineering - RSDP',IgnoreCase=$true)][string]$Project = 'MBU Engineering'        
    )

    begin {
        $token = (Get-RackerToken).XAuthToken.'x-auth-token'
        $headers = @{'Content-Type' = 'application/json'; 'Accept' = 'application/json'; 'X-Auth-Token' = $token}
        
        # Get Project 'ID' from 'Name'
        $PWSafeProjects = Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects" -Headers $headers
        $PWSafePrjID = ($PWsafeProjects.Project | Where-Object {$_.name -eq "$Project"}).id
    }
    
    process {
        # Get all Passwords in a Project
        $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName}
        
        if ($Maglibs) {
            $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName -and $_.description -match 'maglib' -and $_.category -eq 'CommVault'} | Select-Object @{Name='Description';Expression='description'}, @{Name='Username';Expression='username'}, @{Name='Password';Expression='password'}, @{Name='Category';Expression='category'}, @{Name='Last Updated';Expression='updated_at'}
        }
        elseif ($LibraryRoot) {
            $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName -and $_.description -match 'root' -and $_.category -eq 'Library'} | Select-Object @{Name='Description';Expression='description'}, @{Name='Username';Expression='username'}, @{Name='Password';Expression='password'}, @{Name='Category';Expression='category'}, @{Name='Last Updated';Expression='updated_at'}
        }
        elseif ($LibraryAdmin) {
            $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName -and $_.description -match 'admin' -and $_.category -eq 'Library'} | Select-Object @{Name='Description';Expression='description'}, @{Name='Username';Expression='username'}, @{Name='Password';Expression='password'}, @{Name='Category';Expression='category'}, @{Name='Last Updated';Expression='updated_at'}
        }
        elseif ($QC) {
            $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName -and $_.category -eq 'Library'} | Select-Object @{Name='Description';Expression='description'}, @{Name='Username';Expression='username'}, @{Name='Category';Expression='category'}, @{Name='Last Updated';Expression='updated_at'}
        }
        else {
            $PWSafeCreds = (Invoke-RestMethod -Uri "https://passwordsafe.corp.rackspace.com/projects/$PWSafePrjID/credentials?per_page=1000" -Headers $headers).credential | Where-Object {$_.description -match $CredName} | Select-Object @{Name='Description';Expression='description'}, @{Name='Username';Expression='username'}, @{Name='Password';Expression='password'}, @{Name='Category';Expression='category'}, @{Name='Last Updated';Expression='updated_at'}
        }
    }

    end {
        Write-Output $PWSafeCreds
    }
    #$LibPass = ConvertTo-SecureString -AsPlainText -String ($MBU_creds | Where-Object { $_.category -match 'Library' -and $_.description -like '*' + $search + '*'  -and $_.username -match 'root'}).password
}

<# 
MBU API - Same headers as Password Safe API
$commcells = Invoke-RestMethod -Uri "https://api.backupcenter.sb.rackspace.com/v2/commcells/?per_page=1000" -Headers $headers 
$ddbs = Invoke-RestMethod -Uri "https://api.backupcenter.sb.rackspace.com/v2/ddbs/?per_page=1000" -Headers $headers
$libs = Invoke-RestMethod -Uri "https://api.backupcenter.sb.rackspace.com/v2/libraries/?per_page=1000" -Headers $headers

# CVwatch Wannabe
$cvwatch.items | Select-Object -Property commcellName, libraryAlias, runningJobs, waitingJobs, pendingJobs, queuedJobs, suspendedJobs, restoreJobs | Sort-Object -Property commcellName | Where-Object {$_.commcellName -ne 'Dummy'}

#>

# Alias
New-Alias -Name g -Value Get-mbuDevice
New-Alias -Name c -Value Connect-mbuDevice
New-Alias -Name pw -Value Get-PWSafe
New-Alias -Name sala -Value Start-AsLocalAdmin

# Export
Export-ModuleMember -Function * -Alias *


# Ideas to add
# Find switchports
# List Snapshots, and maybe create or delete them.
# Get-Fireall $mbuDevices
# Get-NetworkSwitchPort $mbuDevices #Will prompt for password on first run
# Get-VmDatastore $mbuDevices
# Get-Backups (interact with MBU API to get info on DDB Backups etc)
# Map drive to lonfiles

# SCP functions would be good.

# Add -QC Swtich to PWSafe
