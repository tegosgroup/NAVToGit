function Get-UpdateAvailable{
    $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" | ConvertFrom-Json
    $currentRepo = (Get-Item $PSScriptRoot).Parent.FullName

    $currentVersion = Get-Content -Path (Join-Path -Path $currentRepo -ChildPath "version") -First 1
    $remoteVersion = $obj.tag_name

    return -Not ($currentVersion -eq $remoteVersion)
}

function Invoke-UpdateProcess{
    $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" | ConvertFrom-Json
    $currentRepo = (Get-Item $PSScriptRoot).Parent.FullName
    $tempRepo = Join-Path -Path $env:TEMP -ChildPath "NavToGitUpdate"
    $downloadFile = Join-Path -Path $tempRepo -ChildPath "update.zip"

    Invoke-WebRequest -Uri "https://github.com/tegosGroup/NAVToGit/archive/v0.1.zip" -OutFile $downloadFile

    Expand-Archive -Path $downloadFile -DestinationPath $tempRepo -Force
    Remove-Item -Path $downloadFile -Force
    
    Get-ChildItem -Path (Get-ChildItem $currentRepo)[0].FullName -Recurse | ForEach-Object {
        Write-Host $_.FullName
    }
}

Get-UpdateAvailable

Invoke-UpdateProcess
