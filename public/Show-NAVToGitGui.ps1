function Show-NAVToGitGui {
    try {
        $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
        $guiconfig = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json") -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Host "JSON cannot be read. Please check configfiles." -ForegroundColor Red
        break
    }

    $Functions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\Functions.ps1"
    . $Functions
    $GuiFunctions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\gui\MainMenu.ps1"
    . $GuiFunctions

    Open-MainMenu
}