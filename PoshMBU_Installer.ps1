
# Identify Module Path
$p = $Env:PSModulePath.Split(';') | Select-object -Index 0

# Create PoshMBU Module Directory
New-Item -Path $p -Name PoshMBU -ItemType Directory

# Declare Module Path
$PoshMBUPath = "$p\PoshMBU"

# Copy Module Files
Invoke-WebRequest -uri https://raw.githubusercontent.com/TruStorey/PoshMBU/master/PoshMBU.psd1 -Outfile $PoshMBUPath\PoshMBU.psd1
Invoke-WebRequest -uri https://raw.githubusercontent.com/TruStorey/PoshMBU/master/PoshMBU.psm1 -Outfile $PoshMBUPath\PoshMBU.psm1

Install-Module $PoshMBUPath\PoshMBU.psd1
Import-Module PoshMBU