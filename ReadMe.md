# READ ME
'ELA_root:' (Extract Logs Automation Root)
 - act as an APP ROOT FOLDER
 - configured gdrive storage in RCLONE 
 - located in work google account > Developer Root > Extract Logs Automation

'UPScans:' (Upload Scans)
 - scans will be stored in this location. Can be change as long as configured in rclone.
 - configured gdrive storage in RCLONE
 - located in dev4 > Log Scans > Upload Scans

'run.ps1'
 - this script will be called by the Task Scheduler
 - it will check any changes in rclone.conf(_config), main.ps1(_src), run.ps1(itself in gdrive file) and update accordingly
 - create backup from the previous working script.
 - run main.ps1 at maximum of 3 attempts if error encoutered during runtime, it recovers backup file and run again.
 - Catch encoutered errors, generate log for this error, and upload it to the UPScans for references.

'main.ps1'
 - download naming_ref.csv for labeling, store in reference folder, and wil be remove after all scans are completed
 - extract Scan and Entry logs in csv format
 - upload scans to UPScans

ADVANCED USAGE
'How to update run.ps1'
 - Since run.ps1 will be called at task scheduler this should be carefully update or script will be unuseable
 - You can update it through main.ps1, add your scripts before <Main> command. The current run.ps1 file will encounter error after changes applied, but will be fine in the next execution.
 - Make sure to test run.ps1 locally if it works, still a backup will be generated upon update but there will be no command to recover it when encountered error.

'How to update files'
 - Simply, replace files in gdrive storage.


Commands:
powershell -windowstyle hidden -ExecutionPolicy Bypass -File "C:\App\\_installer.ps1"
- executed when running .exe file
