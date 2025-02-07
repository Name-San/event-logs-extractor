$home_dir = "C:\App"
schtasks /create /tn "GetLogs" /xml $home_dir\config\task.xml /f
& $home_dir\dialog\add_user.ps1
& "$home_dir\own.ps1"
rm -force -recurse "$home_dir\config\task.xml", "$home_dir\dialog", $home_dir\_installer.ps1

exit 0
