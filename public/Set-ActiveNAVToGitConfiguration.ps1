function Set-ActiveNAVToGitConfiguration {
    param(
        $useConfig
    )
    try {
        $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Host "JSON cannot be read. Please check configfile." -ForegroundColor Red
        break
    }

    $Functions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\Functions.ps1"
    . $Functions

    Get-ConfigFileIntegrity -config $config

    if ($null -eq $useConfig) {
        Get-ObjectMembers $config | ForEach-Object {
            if (-not ($_.key -like "active")) {
                Write-Host $_.key -ForegroundColor Cyan
                $_.value | Format-List
            }
        }
        $useConfig = Read-Host "Please enter the configuration name you want to activate"
    }

    $activated = $false
    Get-ObjectMembers $config | ForEach-Object {
        if (($_.key -like $useConfig)) {
            $config.active = $_.key
            $useConfig = $_.key
            $config | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json")
            Write-Host "NAVToGit configuration $useConfig is now active!" -ForegroundColor Cyan
            $activated = $true
        }
    }
    
    if (-not $Activated) {
        Write-Host "NAVToGit configuration $useConfig could not be found. Aborting." -ForegroundColor Red
    }
}
