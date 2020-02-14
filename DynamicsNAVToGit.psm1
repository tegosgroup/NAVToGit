function Get-ObjectMembers {
    Param(
        [PSCustomObject]$obj
    )
    $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        [PSCustomObject]@{key = $key; value = $obj."$key" }
    }
}

$autoUpdater = Join-Path -Path $PSScriptRoot -ChildPath "private\AutoUpdater.ps1"
. $autoUpdater

if (Get-UpdateCheckNeeded) {
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

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Private = $Private + (Get-ChildItem -Path $PSScriptRoot\Private\gui\*.ps1 -ErrorAction SilentlyContinue)

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

if (-not (Test-Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\") -ErrorAction SilentlyContinue)) {
    New-Item (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\") -ItemType Directory
}

if (-not (Test-Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction SilentlyContinue)) {
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -Childpath ".config\config.json") -Destination (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json")
    $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
    Get-ObjectMembers $config | ForEach-Object {
        if (-not ($_.key -eq "active")) {
            $config.$($_.key).Tempfolder = $env:TEMP
        }
    }
    $config | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json")
    Write-Host "No config.json found in $(Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\") - sample config.json has been generated."
}

if (-not (Test-Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json") -ErrorAction SilentlyContinue)) {
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -Childpath ".config\gui.config.json") -Destination (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json")
    Write-Host "No gui.config.json found in $(Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\") - sample gui.config.json has been generated."
}

if (-not (Test-Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\ThirdPartyIdAreas.json") -ErrorAction SilentlyContinue)) {
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -Childpath ".config\ThirdPartyIdAreas.json") -Destination (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\ThirdPartyIdAreas.json")
    Write-Host "No ThirdPartyIdAreas.json found in $(Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\") - sample ThirdPartyIdAreas.json has been generated."
}

Export-ModuleMember -Function $Public.Basename
Write-Host "NAV Git Module has been loaded."