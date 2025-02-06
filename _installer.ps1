$env:RCLONE_CONFIG = "C:\App\config\rclone.conf"

# copy all ps1 files
rclone copy ELA_Root:_src\main.ps1 C:\App
rclone copy ELA_Root:_src\run.ps1 C:\App

schtasks /create /tn "GetLogs" /xml C:\App\config\task.xml /f

& C:\App\dialog\add_user.ps1

icacls C:\App /inheritance:r /grant Admin:F /grant System:F /T /Q

exit 0 
