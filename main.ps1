# Define the output directory
$outputDir = "C:\Logs"

# Ensure the output directory exists
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
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

# Determine if today is the last working day
function Main {
    $lastWorkingDay = Get-Date
    $today = Get-Date

    if ($today -eq $lastWorkingDay) {
        Write-Output "Running script on the last working day of the month: $lastWorkingDay"

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
        # 1. Get Application logs for the last month
        Get-WinEvent -FilterHashtable @{LogName="Application"; StartTime=(Get-Date).AddMonths(-1); EndTime=(Get-Date)} |
        ForEach-Object { Format-LogEntry $_ } |
        Export-Csv -Path "$outputDir\resultAdmin.csv" -NoTypeInformation

        # 2. Get Security logs with Event ID 4624 (Successful Logons)
        Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4624} |
        ForEach-Object { Format-LogEntry $_ } |
        Export-Csv -Path "$outputDir\Logons Logs.csv" -NoTypeInformation

        # 3. Get Security logs with Event ID 4625 (Failed Logins)
        Get-WinEvent -FilterHashtable @{LogName="Security"; Id=4625} |
        ForEach-Object { Format-LogEntry $_ } |
        Export-Csv -Path "$outputDir\Failed Login Logs.csv" -NoTypeInformation

        Write-Output "Logs successfully exported to $outputDir"
    } else {
        Write-Output "Today is not the last working day of the month. Script will not run."
    }
}

Main
