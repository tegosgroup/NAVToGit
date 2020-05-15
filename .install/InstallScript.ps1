# NAVToGit Install Script

Write-Host("$(Get-Date -Format "HH:mm:ss") | Starting NAVToGit Module installation") -ForegroundColor White
$approval = Read-Host ("$(Get-Date -Format "HH:mm:ss") | Do you want to continue? [y/n]")
if ($approval -ne "y") {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Cancelled NAVToGit module installation") -ForegroundColor Red
    break
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
}
catch {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | No connection to Github.") -ForegroundColor Red
    break
}
$temp = Join-Path -Path $env:TEMP -ChildPath "NavToGitUpdate"
$downloadFile = Join-Path -Path $temp -ChildPath "update.zip"

Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue > $null
New-Item -path $temp -ItemType Directory > $null

Write-Host("$(Get-Date -Format "HH:mm:ss") | Downloading latest release...") -ForegroundColor Cyan
Invoke-WebRequest -Uri $obj.zipball_url -OutFile $downloadFile

Write-Host("$(Get-Date -Format "HH:mm:ss") | Extracting download zip") -ForegroundColor White
Expand-Archive -Path $downloadFile -DestinationPath $temp -Force

$userPath = "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments))\WindowsPowerShell\Modules\NAVToGit"
if (-not (Test-Path -Path $userPath)) {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating directory C:$userPath") -ForegroundColor Cyan
    New-Item -Path $userPath -ItemType Directory > $null
}

Write-Host("$(Get-Date -Format "HH:mm:ss") | Moving new files") -ForegroundColor Cyan
Robocopy (Get-ChildItem $temp)[0].FullName $userPath /mov /mir /xd .git > $null

Write-Host("$(Get-Date -Format "HH:mm:ss") | Deleting temp folder $temp") -ForegroundColor White
Remove-Item -Path $temp -Recurse -Force

$approval = Read-Host ("$(Get-Date -Format "HH:mm:ss") | Do you want to create a desktop shortcut to the NAVToGitGui? [y/n]")
if ($approval -eq "y") {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating Desktop Shortcut for GUI") -ForegroundColor White
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop))\Show-NAVToGitGui.lnk")
    $Shortcut.TargetPath = "$env:WINDIR\system32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-command Show-NAVToGitGui"
    $Shortcut.Save()
}

Write-Host("$(Get-Date -Format "HH:mm:ss") | NAVToGit Module has been installed.") -ForegroundColor Green
