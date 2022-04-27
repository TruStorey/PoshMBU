<#
 .Synopsis
  MBU Engineering Module for PoshCore and RaxUtilities.

 .Description
  Powershell cmdlets to interact with Core focused on MBU Engineering.

 .Parameter Hostname
  This is a wild card search e.g. "CS0901", "CS0404DD", "CS0802DM02". NOTE: All hostnames are case sensitive. 

 .Example
   # Shows a list of all devices with CS0404 in the Hostname and their Core Status.
   Get-mbuDevice CS0404

 .Example
   # Display a date range.
   Show-Calendar -Start "March, 2010" -End "May, 2010"

#>

# Requried Modules for this to work!
#Requires -Modules ModuleManager, PoshCore, RaxUtilities

# Search Device by Hostname in Account 27928
function Get-mbuDevice {
    param (
        [Parameter(Position = 0, Mandatory)]$Device,
        [Parameter()][switch]$DRAC,
        [Parameter()][switch]$IPs,
        [Parameter()][switch]$ShowCreds,
        [Parameter()][switch]$Virt,
        [Parameter()][switch]$vCenter,
        [Parameter()][switch]$vPortal,
        [Parameter()][switch]$OpenCore,
        [Parameter()][int]$SearchAccount = 27928,
        [Parameter()][switch]$TypeRackPass,
        [Parameter()][int]$TypeTimer = 5,
        #[Parameter(ParameterSetName = 'ByStatus')][ValidateSet('DFW3' ,'ORD1' ,'IAD3' ,'IAD4' ,'LON3' ,'LON5' ,'LON6' ,'LON7' ,'FRA1' ,'FRA30' ,'HKG2' ,'HKG5' ,'SYD2' ,'SYD4' ,'SIN2' ,'SIN30' ,'SIN80' ,'NYC2' ,'SJC2' ,'MCI1' ,'SHA2',IgnoreCase=$true)][string]$DC, 
        [Parameter(ParameterSetName = 'ByStatus')][switch]$Inactive
    )

    $CoreError = $false

    # Test if Hostname or Device Number was passed in parameters.
    if ($Device.GetType().Name -eq 'Int32') {
        $mbuDevices = $Device
    }
    elseif ($Device.GetType().Name -eq 'String') {
        
            #$mbuDevices = (Find-CoreComputerByHostname -Account $SearchAccount -Hostname $Device | Select-Object number).number
        
        # Need to work out logic to try upper case and lower case names 

        $mbuDevices = (Find-CoreComputerByHostname -Account $SearchAccount -Hostname $Device | Select-Object number).number
        if ($mbuDevices) {
            $mbuDevices = $mbuDevices
        }
        else {
            $DeviceToUpper = $Device.ToUpper()
            $mbuDevices = (Find-CoreComputerByHostname -Account $SearchAccount -Hostname $DeviceToUpper | Select-Object number).number
            if ($mbuDevices) {
            }
            else {
                $DeviceToLower = $Device.ToLower()
                $mbuDevices = (Find-CoreComputerByHostname -Account $SearchAccount -Hostname $DeviceToLower | Select-Object number).number
            }
        }
    }
 
    if ($Inactive) { 
        try {
            $Results = Find-CoreComputer -Computers @($mbuDevices) | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='Status';Expression='status_name'}
        }
        catch {
            $CoreError = $true         
        }
    } 
    elseif ($DRAC) {
        try {
            $Results = Find-CoreComputer -Computers @($mbuDevices) -Attributes Drac | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='DRAC IP';Expression='drac_ips'},@{Name='DRAC User';Expression='drac_usernames'},@{Name='DRAC Password';Expression='drac_passwords'}}
        catch {
            $CoreError = $true         
        }
    }
    elseif ($ShowCreds) {
        try {
            $Results = Find-CoreComputer -Computers @($mbuDevices) -Attributes Password | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='Rack Pass';Expression='rack_password'},@{Name='Admin Pass';Expression='admin_password'}}
        catch {
            $CoreError = $true         
        }
    }
    elseif ($IPs) {
        try {
        #$Results = Find-CoreComputer -Computers @($mbuDevices) -Attributes Network
            $Results = Get-NetworkInformation -Device $mbuDevices | Select-Object Device,@{Name='Hostname';Expression='DeviceName'},@{Name='Public IP';Expression='PublicIp'},@{Name='ServiceNet IP';Expression='ServiceNetIp'},AggExZone
        }
        catch {
            $CoreError = $true         
        }
    }
    elseif ($Virt) {
        try {
            $Results = Get-VmInformation -Device $mbuDevices | Select-Object Device,@{Name='Hostname';Expression='DeviceName'},DC,Networks,PowerState,Hypervisor,HypervisorClusterName,VCenter
        }
        catch {
            $CoreError = $true         
        }
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
        try { 
            Show-CoreComputer -Computer $mbuDevices
        }
        catch {
            $CoreError = $true         
        }
    }
    elseif ($TypeRackPass) {
        try {
            $RackPassword = (Find-CoreComputer -Computers @($mbuDevices) -Attributes Password).rack_password
        }
        catch {
            $CoreError = $true         
        }
        if ($RackPassword) {
            $Typer = New-Object -ComObject wscript.shell;
            Start-Sleep $TypeTimer
            $Typer.SendKeys($RackPassword)
        }
    }
    else { 

        #$Results = Find-CoreComputer -Computers @($mbuDevices) | Where-Object {$_.status_name -match 'Online/Complete'} | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='Status';Expression='status_name'}

        # This is screwing all the other if statements
        try {
            $Results = Find-CoreComputer -Computers @($mbuDevices) | Where-Object {$_.status_name -match 'Online/Complete'} | Select-Object @{Name='Device';Expression='number'},@{Name='Hostname';Expression='name'},@{Name='DC';Expression='datacenter_symbol'},@{Name='Status';Expression='status_name'}
        }
        catch {
            $CoreError = $true         
        }
   
    }
    if ($CoreError) {
        $Results = (Write-Warning "Could not find a Core device with name '$DeviceToUpper' or '$DeviceToLower'. `n`rPROTIP: You either fat fingered it, or the device name in Core is written in CamelCase.`n") 
    }
    else { 
        $Results = $Results
    }

    Write-Output $Results
    
}

function Connect-mbuDevice {
    param (
        [Parameter(Position = 0, Mandatory)]$Device,
        [Parameter()][ValidateSet('ORD1','LON5',IgnoreCase=$true)][string]$Gateway="LON5",
        [Parameter()][switch]$LoginAsRack,
        [Parameter()][switch]$Isilon,
        [Parameter()][int]$SearchAccount = 27928,
        [Parameter()][switch]$TypeRackPass,
        [Parameter()][int]$TypeTimer = 5,
        #[Parameter(ParameterSetName = 'ByStatus')][ValidateSet('DFW3' ,'ORD1' ,'IAD3' ,'IAD4' ,'LON3' ,'LON5' ,'LON6' ,'LON7' ,'FRA1' ,'FRA30' ,'HKG2' ,'HKG5' ,'SYD2' ,'SYD4' ,'SIN2' ,'SIN30' ,'SIN80' ,'NYC2' ,'SJC2' ,'MCI1' ,'SHA2',IgnoreCase=$true)][string]$DC, 
        [Parameter(ParameterSetName = 'ByStatus')][switch]$Inactive
    )

    # Test if Hostname or Device Number was passed in parameters.
    if ($Device.GetType().Name -eq 'Int32') {
        $mbuDevices = $Device
    }
    elseif ($Device.GetType().Name -eq 'String') {
        
        $mbuDevices = (Find-CoreComputerByHostname -Account $SearchAccount -Hostname $Device | Select-Object number).number          
    }

    if ($Gateway -eq 'LON5') {
        $mbuGW = 'mbu.lon5.gateway.rackspace.com'
    }
    else {
        $mbuGW = 'mbu.ord1.gateway.rackspace.com'
    }

    # Convert Device name to Upper case for pretty output
    $UpCaseDevice = $Device.ToUpper()
    $DevHostname = (Find-CoreComputer -Computers @($mbuDevices) | Select-Object name).name
    $DevOSType = (Find-CoreComputer -Computers @($mbuDevices) -Attributes Os | Select-Object os_type).os_type
    $DevUser = $env:USERNAME

    if ($LoginAsRack) {
        $LoginCreds = Get-mbuDevice $mbuDevices -ShowCreds
        Write-Output $LoginCreds
        $DevUser = 'rack'
        $RackPass = $LoginCreds."Rack Pass"
        }
    else {

        $DevUser = $env:USERNAME
    }

    if ($DevOSType -like "*Windows"){
        Write-Output "`nConnecting to $mbuDevices ($UpCaseDevice) using RoyalTS Application default settings`r`n"
        if ($LoginAsRack) {
        Invoke-Command -ScriptBlock {& cmd /c "C:\Program Files (x86)\Royal TS V5\RoyalTS.exe" /protocol:rdp /using:uri /uri:$DevHostname /username:rack /password:$RackPass}
        #Write-Output "protocol:rdp /using:uri /uri:$DevHostname /username:rack /password:$RackPass"
        }
        else {
        Invoke-Command -ScriptBlock {& cmd /c "C:\Program Files (x86)\Royal TS V5\RoyalTS.exe" /protocol:rdp /using:uri /uri:$DevHostname}
        }
    }
    elseif ($DevOSType -like "*Linux"){

        Write-Output "`nConnecting to $mbuDevices ($UpCaseDevice) as user '$DevUser' via the $Gateway MBU gateway `r`n"
        Invoke-Command -Script { ssh -A gu=$env:USERNAME@$DevUser@$DevHostname@$mbuGW }
        #Write-Host "ssh -A gu=$env:USERNAME@$DevUser@$DevHostname@$mbuGW"
    }
    elseif ($Isilon) {
        Invoke-Command -Script { ssh -A gu=$env:USERNAME@root@$Device@$mbuGW }
        #Write-Output "ssh -A gu=$env:USERNAME@root@$Device.storage.rackspace.com@$mbuGW"
    }
    else {
        Write-Error -Message "Not device type in Core, unable to identify how to logon"
    }

}

function Get-RackerTools {
    param (
        [Parameter(Position = 0)]$Racker,
        [Parameter()][switch]$LocalAdminPass
    )

    # Compare CSVs for SP Copy comparison
    <#$CSV1 = Import-CSV -Path
    $CSV2 = Import-CSV -Path
    foreach ($Item in $CSV1.ColA) 
    { if ($Item -in $CSV2.ColA) 
        { 

        } 
        else 
        { Write-Output "Job $Item from CSV1 doesn't exist in CSV2" } 
    }
    #>
    # Password Safe API calls

    <#
    $preToken = Get-RackerToken
    $token = ($preToken).XAuthToken.'x-auth-token'
    curl -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: $token" https://passwordsafe.corp.rackspace.com/projects/
    #>
    
    if ($LocalAdminPass) {
        Get-RackerAdminPassword
    }
    else {
    Get-Racker -Name $Racker
    }
}

function Get-PWSafe {
    param (
        [Parameter(Position = 0)]$Credential,
    )

    #Get Token
    $token = (Get-RackerToken).XAuthToken.'x-auth-token'
    #PWSafe_API1 = curl -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: $token" https://passwordsafe.corp.rackspace.com/projects/
    #Get all Passwords in a Project = (curl -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Auth-Token: $token" https://passwordsafe.corp.rackspace.com/projects/1315/credentials?per_page=1000 | ConvertFrom-JSON).credential
    #$LibPass = ConvertTo-SecureString -AsPlainText -String ($MBU_creds | Where-Object { $_.category -match 'Library' -and $_.description -like '*' + $search + '*'  -and $_.username -match 'root'}).password
}

Export-ModuleMember -Function Get-mbuDevice, Connect-mbuDevice, Get-RackerTools, Get-PWSafe

# Find switchports

# SSH to Linux Devices from Powershell

# Launch RoyalTS to connect to Windows devices

# Search Password Safe Password

# List Snapshots, and maybe create or delete them.

# Get-Fireall $mbuDevices

# Get-NetworkSwitchPort $mbuDevices #Will prompt for password on first run

# Get-VmDatastore $mbuDevices