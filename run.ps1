$env:RCLONE_CONFIG = "C:\App\config\rclone.conf"
$home_dir = "C:\App"
$local_main = "C:\App\main.ps1"
$backup_main = "C:\App\main.ps1_backup"
$cloud_main = "UPScans:_src\main.ps1"

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

# Generate logs for error
function Generate-Log {
    param($entry)
    Get-Content -Path "C:\App\config\user.prof" | ForEach-Object {
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

    $result = powershell -File C:\App\main.ps1

    if ($result -ne "Success") {
        cp -path $backup_main -destination $local_main -force

        $attempt++
        $run = (Run-Main -attempt $attempt) + "`n$result"
        return $run 
    }   

    return "Success"
    
}

# Check for changes in cloud main file
$remote = rclone md5sum $cloud_main
$local = rclone md5sum $local_main
if (-not ($remote -eq $local)) {
    Copy-Item -Path $local_main -Destination "$home_dir\main.ps1_backup" -Force
    rclone copy $cloud_main C:\App
} else {
    Write-Output "File is up-to-date!"
}

$report = Run-Main -attempt 0
if(-not($report -eq "Success")) {
    Generate-Log -entry $report
}
exit
