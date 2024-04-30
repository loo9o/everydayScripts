# Define the folder name
$folderName = "IPLogs"

# Construct the full path
$logPath = Join-Path -Path $env:USERPROFILE -ChildPath ("Documents\$folderName")

# Ensure the folder exists, if not, create it
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}

# Get all network interfaces that meet the criteria
$networkInterfaces = Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -ne "Loopback" -and $_.InterfaceAlias -ne "Teredo"}

# Get the current year and month
$year = Get-Date -Format "yyyy"
$month = Get-Date -Format "MM"
$date = Get-Date -Format "yyyy-MM-dd"

# Name of the log file in JSON format
$jsonFileName = "IP_Log_${year}-${month}.json"
$jsonFile = Join-Path -Path $logPath -ChildPath $jsonFileName

# Name of the log file in text format
$txtFileName = "IP_Log_${year}-${month}.txt"
$txtFile = Join-Path -Path $logPath -ChildPath $txtFileName

# Check if the JSON file exists, if not, create it
if (-not (Test-Path -Path $jsonFile)) {
    $interfacesInfo = @()
} else {
    # Read the existing JSON file
    $interfacesInfo = Get-Content -Path $jsonFile | ConvertFrom-Json
}

# Create an object for each interface and add it to the array
foreach ($interface in $networkInterfaces) {
    $ip = $interface.IPAddress
    $interfaceName = $interface.InterfaceAlias
    $dnsSuffix = $interface.DNSSuffix
    $time = Get-Date -Format "HH:mm:ss"
    $fullInterfaceName = (Get-NetAdapter | Where-Object {$_.InterfaceAlias -eq $interfaceName}).Name

    # Check if $fullInterfaceName is null
    if ($null -eq $fullInterfaceName) {
        Write-Host "Interface not found for Alias: $interfaceName"
        continue  # Skip to the next interface
    }

    # Get additional information of the interface
    $interfaceDetails = Get-NetAdapter -Name $fullInterfaceName

    # Create an object to store interface information
    $interfaceInfo = [PSCustomObject]@{
        Date = $date
        Time = $time
        InterfaceName = $fullInterfaceName
        InterfaceAlias = $interfaceName
        IPAddress = $ip
        Status = $interfaceDetails.Status
        MacAddress = $interfaceDetails.MacAddress
        MediaType = $interfaceDetails.MediaType
        Speed = $interfaceDetails.Speed
        Description = $interfaceDetails.InterfaceDescription
    }

    # Add the object to the array
    $interfacesInfo += $interfaceInfo
}

# Convert the array of objects into JSON format and save it to a file
$interfacesInfo | ConvertTo-Json | Out-File -FilePath $jsonFile -Force

# Save the information to the text file in a readable format
foreach ($interfaceInfo in $interfacesInfo) {
    $logEntry = "$($interfaceInfo.Date) $($interfaceInfo.Time) - Interface: $($interfaceInfo.InterfaceName), IP Address: $($interfaceInfo.IPAddress)"
    Add-Content -Path $txtFile -Value $logEntry
}



