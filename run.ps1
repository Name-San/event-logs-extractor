$home_dir = "C:\App"
$env:RCLONE_CONFIG = "$home_dir\config\rclone.conf"
$local_main = "$home_dir\main.ps1"
$backup_main = "$home_dir\main.ps1_backup"
$cloud_main = "ELA_Root:_src\main.ps1"
$cloud_rclone = "ELA_Root:_config\rclone.conf" 
$local_rclone = "$home_dir\config\rclone.conf"
$isupdated = $true

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

# Generate logs for error
function Generate-Log {
    param($entry)
    Get-Content -Path "$home_dir\config\user.prof" | ForEach-Object {
        if ($_ -match "device:\s*(.+)") {
            $user = $matches[1].Trim()
        }
    }

    # Generate log file
    Write-Output "$entry" > $home_dir\$user.log

    # Send to cloud
    rclone copy $home_dir\$user.log UPScans:

    # Clean
    rm -force $home_dir\$user.log
    
}

# Run main file recursively
function Run-Main {
    param([int]$attempt)

    if ($attempt -eq 3) {
        return "Error: Max attempt in running main.ps1"
    }

    $result = & "$home_dir\main.ps1"
    
    if ($result -ne "Success" -and $result -ne "False") {
        cp -path $backup_main -destination $local_main -force
        $attempt++
        $run = (Run-Main -attempt $attempt) + "`n($attempt): $result"
        return $run 
    }

    return "Success"
    
}

# Update run.ps1 file using run.ps1_new
if (Compare-Files -a "ELA_Root:_src\run.ps1" -b "$home_dir\run.ps1") {
    Copy-Item -Path "$home_dir\run.ps1" -Destination "$home_dir\run.ps1_backup" -Force
    rclone copy "ELA_Root:_src\run.ps1" "$home_dir"
    $isupdated = $true
}

# Check for changes in cloud main file
Check-Rclone
if (Compare-Files -a $cloud_main -b $local_main) {
    Copy-Item -Path $local_main -Destination "$home_dir\main.ps1_backup" -Force
    rclone copy $cloud_main $home_dir
    $isupdated = $true
}

# check for changes in rclone config
if (Compare-Files -a $cloud_rclone -b $local_rclone) {
    rclone copy $cloud_rclone $home_dir\config
    $isupdated = $true
}

# Call Run-Main while waiting for the result to generate report
$report = Run-Main -attempt 0
if(-not($report -eq "Success")) {
    Generate-Log -entry $report
}

if($isupdated) {     
    & "$home_dir\own.ps1"
}

exit