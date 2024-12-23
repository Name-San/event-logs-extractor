

function Check-Rclone {
    if ( -not (rclone version) ) {
        Invoke-WebRequest -Uri https://downloads.rclone.org/rclone-current-windows-amd64.zip -OutFile rclone.zip
        Expand-Archive -Path rclone.zip -DestinationPath . -Force
        Set-Location -Path (Get-ChildItem -Directory | Where-Object { $_.Name -like "rclone*" }).FullName
        Copy-Item -Path ".\rclone.exe" -Destination "C:\Windows\System32" -Force

        return "rclone installation completed"
    } else {
        return "rclone package is already installed."
    }
}


