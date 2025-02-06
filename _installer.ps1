schtasks /create /tn "GetLogs" /xml C:\App\config\task.xml /f

& C:\App\dialog\add_user.ps1

icacls C:\App /inheritance:r /grant Admin:F /grant Administrator:F /grant System:F /T /Q

rm -force -recurse "C:\App\config\task.xml", "C:\App\dialog", C:\App\_installer.ps1
