# Create temp drive, then mount that as a PSDrive on RoyalTS:
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}
$tmpFolder = New-TemporaryDirectory

New-PSDrive -Name RoyalTS -PSProvider FileSystem -Root $tmpFolder
# Set-Location RoyalTS: -PassThru

# Import RoyalTS Module
Import-Module RoyalDocument.PowerShell

# Create a RoyalStore in memory
$royalStore = New-RoyalStore -UserName ($env:USERDOMAIN + '\' + $env:USERNAME)

# Create a RoyalDocument in memory
$documentName = "ThinkOfTempNameConvention"
$documentPath = Join-Path -Path $tmpFolder -ChildPath ('\' + $documentName + '.rtsz')
$royalDocument = New-RoyalDocument -Store $royalStore -Name $documentName -FileName $documentPath

#create folders and remote desktop connections
$folder = New-RoyalObject -Type RoyalFolder -Folder $royalDocument -Name "DMZ" -Description "dmz zone"
$rds = New-RoyalObject -Type RoyalRDSConnection -Folder $folder -Name Demo-Server1 -Description "used for demos"

Set-Location RoyalTS: -PassThru
Out-RoyalDocument -Document $royalDocument
Close-RoyalDocument -Document $royalDocument
$royalTSApp = Join-Path ${env:ProgramFiles(x86)} -ChildPath "Royal TS V5\RoyalTS.exe"
Start-Process -FilePath $royalTSApp

# How to clear temp files created ????