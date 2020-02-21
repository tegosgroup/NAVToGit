function Update-NAVToGit {
    $autoUpdater = Join-Path -Path $PSScriptRoot -ChildPath "..\private\AutoUpdater.ps1"
    . $autoUpdater

    if (Get-UpdateAvailable) {
        while ((-not ($decision -eq "y")) -and (-not ($decision -eq "n"))) {
            $decision = Read-Host "$(Get-Date -Format "HH:mm:ss") | Do you want to apply the update? [y/n]"
            if ($decision -eq "y") {
                Invoke-UpdateProcess
            }
            elseif ((-not ($decision -eq "y")) -and (-not ($decision -eq "n"))) {
                Write-Host("$(Get-Date -Format "HH:mm:ss") | Wrong input") -ForegroundColor Red
            }
        }
    }
}