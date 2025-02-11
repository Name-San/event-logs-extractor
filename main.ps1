$home_dir = "C:\App"
$env:RCLONE_CONFIG = "$home_dir\config\rclone.conf"
$RCLONE_STORE = "UPScans"

# Function to calculate the last working day of the current month
function Get-LastWorkingDay {
    $today = Get-Date
    $lastDayOfMonth = (Get-Date -Year $today.Year -Month $today.Month -Day 1).AddMonths(1).AddDays(-1)

    # Adjust for weekends
    switch ($lastDayOfMonth.DayOfWeek) {
        'Saturday' { $lastDayOfMonth.AddDays(-1) }
        'Sunday'   { $lastDayOfMonth.AddDays(-2) }
        default    { $lastDayOfMonth }
    }
}

# Download naming references in the drive
function Get-Records {
    if (-not(Test-Path .\reference)) {
        New-Item -ItemType Directory -Path .\reference > $null
    }

    rclone copy ELA_Root:_db_names .\reference

    if (-not(Test-Path .\reference\naming_ref.csv)) {
        throw "Missing reference file in cloud."
    }

    return
}

# Upload generated logs in selected drive folder
function Upload-Files {
    param([string]$folder, [string]$user)
    Get-Content -Path  $user | ForEach-Object {
        if ($_ -match "site:\s*(.+)") {
            $site = $matches[1].Trim()
        }
    }
    rclone copy ".\logs" "${RCLONE_STORE}:$site\${folder}"

    return
}

# Extract coresponded username in naming ref
function Verify-FileNames {
    param([string]$user,[string]$ref,[int]$attempt)
    Write-output "$attempt"
    if ($attempt -eq 3) {
        throw "Failed to fetch naming."
    }

    if(-not(Test-Path $user)) {
        throw "Missing user profile."
    }

    if (-not(Test-Path $ref)) {
        Get-Records
    }

    # Look for device id
    Get-Content -Path  $user | ForEach-Object {
        if ($_ -match "device:\s*(.+)") {
            $device = $matches[1].Trim()
        }
    }

    # Retrieve correspondede folder and file
    Get-Content -Path $ref | ForEach-Object {
        if ($_ -imatch "$device,(.+),(.+)") {
            $folder = $matches[1].Trim()  
            $file = $matches[2].Trim()
        }
    }

    foreach ($item in @($device, $folder, $file)) {
        if (-not ($item)) {
            $attempt++
            return Verify-FileNames -user $user -ref $ref -attempt $attempt
        }
    }

    [PSCustomObject]@{
        Device = $device
        Folder = $folder
        File   = $file
    }
   
}

# Compare two file using rclone md5sum to check if changes are present
function Compare-Files {
    param($a,$b)
    $itemA = rclone md5sum $a
    $itemB = rclone md5sum $b
    if($itemA -ne $itemB) {
        return $true
    }
    return $false
}

# Helper function to format the log data
function Format-LogEntry {
    param ($entry)
    [PSCustomObject]@{
        Level       = $entry.LevelDisplayName
        'Date and Time' = $entry.TimeCreated
        Source         = $entry.ProviderName
        'Event ID'     = $entry.Id
        'Task Category' = $entry.TaskDisplayName
        Message       = $entry.Message  # Replace newlines for better CSV readability
    }
}

# Return false to other computers.
function Run-Only {
    param($device, $users)
    foreach ($user in $users) {
        if ($device -eq $user) {
            return $true
        }
    }
    return $false
    
}

# Determine if today is the last working day
function Main {
    param($arg)
    $lastWorkingDay = Get-LastWorkingDay
    $today = Get-Date

    if (($today.Day -eq $lastWorkingDay.Day) -or ($arg -eq "--force-run")) {
        
        # Ensure the output directory exists
        $outputDir = ".\logs"
        $applicationDir = "$outputDir\Scan Logs"
        $securityDir = "$outputDir\Entry Logs"
        $ref = ".\reference\naming_ref.csv"
        $user = ".\config\user.prof"
        
        try {
            $result = Verify-FileNames -user $user -ref $ref -attempt 0
            $device = $result.Device
            $file = $result.File
            $folder = $result.Folder
    
            # Specify to run for certain user only, uncomment to use
            # $users = @("PC72", "PC18", "PC35") # Add list of users
            # $device_ok = Run-Only -device $device -users $users
            # if (-not ($device_ok)) {
            #     rm -recurse -force ".\reference"
            #     return $false
            # }
    
            if (-not (Test-Path $outputDir)) {
                New-Item -ItemType Directory -Path $applicationDir > $null
                New-Item -ItemType Directory -Path $securityDir > $null
            }        
           
            # 1. Get Application logs for the last month
            Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{LogName="Application"; StartTime=(Get-Date).AddMonths(-1); EndTime=(Get-Date)} |
            ForEach-Object { Format-LogEntry $_ } |
            Export-Csv -Path "$applicationDir\$file.csv" -NoTypeInformation 
    
            # 2. Get Security logs with Event ID 4624 (Successful Logons)
            Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{LogName="Security"; Id=4624; StartTime=(Get-Date).AddMonths(-1); EndTime=(Get-Date)} |
            ForEach-Object { Format-LogEntry $_ } |
            Export-Csv -Path "$securityDir\Logons Logs.csv" -NoTypeInformation
    
            # 3. Get Security logs with Event ID 4625 (Failed Logins)
            Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{LogName="Security"; Id=4625; StartTime=(Get-Date).AddMonths(-1); EndTime=(Get-Date)} |
            ForEach-Object { Format-LogEntry $_ } |
            Export-Csv -Path "$securityDir\Failed Login Logs.csv" -NoTypeInformation
            
            # Upload logs to google drive using rclone
            $response = Upload-Files -folder $folder -user $user
    
            # Clean
            rm -recurse -force $outputDir, ".\reference"
            
            return "Success"
            
        } catch {
            rm -recurse -force $outputDir, ".\reference"
            return $_
            exit 1
        }

    } else {
        return "False"
    }
}

#Check-Rclone
cd $home_dir

# Additional code you can enter for update files aside main.ps1

# Main program
Main "--force-run"
exit 0
