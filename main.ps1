# Check if rclone is installed
function Check-Rclone {
    $test_path = "C:\Windows\System32\rclone.exe"
    if ( -not (Test-Path $test_path) ) {
        Invoke-WebRequest -Uri https://downloads.rclone.org/rclone-current-windows-amd64.zip -OutFile rclone.zip
        Expand-Archive -Path rclone.zip -DestinationPath . -Force
        $folder_path = (Get-ChildItem -Directory | Where-Object { $_.Name -like "rclone*" }).FullName
        Copy-Item -Path "$folder_path\rclone.exe" -Destination "C:\Windows\System32" -Force
        Remove-Item -force -recurse $folder_path, rclone.zip
        Write-Output "Installation completed"
    } else {
        Write-Output "Installed already"
    }
    return  
}

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

function Get-Records {
    rclone copy UPScans:db_names .\reference
    return
}

function Upload-Files {
    param($folder_dir)
    rclone copy ".\logs" UPScans:$folder_dir
    return
}

# Determine if today is the last working day
function Main {
    $lastWorkingDay = Get-Date
    $today = Get-Date

    if ($today -eq $lastWorkingDay) {
        Write-Output "Running script on the last working day of the month: $lastWorkingDay"
        
        # Ensure the output directory exists
        #$env:RCLONE_CONFIG = ".\config\rclone.conf"
        $outputDir = ".\logs"
        $applicationDir = "$outputDir\Scan Logs"
        $securityDir = "$outputDir\Entry Logs"
        $ref = ".\reference\naming_ref.csv"
        $user = ".\config\user.prof"

        if (-not (Test-Path $outputDir)) {  
            New-Item -ItemType Directory -Path $outputDir > $null
            New-Item -ItemType Directory -Path $applicationDir > $null
            New-Item -ItemType Directory -Path $securityDir > $null
        }

        if (Test-Path $user) {
            Get-Content -Path  $user | ForEach-Object {
                if ($_ -match "device:\s*(.+)") {
                    $device = $matches[1].Trim()
                }
            }
        } else {
            return "Missing user profile."
        }

        if (-not(Test-Path $ref)) {
            Get-Records
        }

        Get-Content -Path $ref | ForEach-Object {
            if ($_ -imatch "$device,(.+),(.+)") {
                $folder = $matches[1].Trim()  
                $file = $matches[2].Trim()
            }
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
        Upload-Files $folder

        Write-Output "Logs successfully exported to $outputDir"
    } else {
        Write-Output "Today is not the last working day of the month. Script will not run."
    }
}

#Check-Rclone
cd C:\App
Main