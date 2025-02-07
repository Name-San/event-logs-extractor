$home_dir = "C:\App"
$administrators=@()

function Check-User {
    $userProfilePath = "$home_dir\config\user.prof"
    $content = Get-Content -Path $userProfilePath
    foreach ($line in $content) {
        if ($line -match "user:\s*(.+)") {
            return $matches[1].Trim()
        }
    }
    return $false
}
$hasAccount = Check-User
if(-not($hasAccount)) {
    $local_administrators = whoami
    foreach ($user in $local_administrators) {
        $string = $user -split "\\"
        $account = $string[1].Trim()
        if ($account -ne "Administrator") {
            $administrators += $account
            echo "user: $account" >> $home_dir\config\user.prof
        }	
    }
} else {
    $administrators += "$hasAccount"
}

Get-ChildItem C:\Users -Name | ForEach-Object {
    $user = $_
    $isAdmin = $administrators -contains "$user"
    if ($isAdmin) {
        takeown /A /F $home_dir /R /D Y
        icacls $home_dir /inheritance:r /grant System:F /grant ${user}:F /T /Q /C
    }
}

exit 0