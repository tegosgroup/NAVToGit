function Get-ThirdPartyJson {
    Param(
        $useConfig,
        $customFilter,
        [pscredential]$Credential
    )
    try {
        $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Host "JSON cannot be read. Please check configfile $($ENV:APPDATA)\NavToGit\config.json" -ForegroundColor Red
        Write-Host $_
        break
    }

    if (Test-Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "ThirdPartyIdAreas.json")) {
        try {
            $thirdpartyfobs = Get-Content -Raw -Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "ThirdPartyIdAreas.json") -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Host "ThirdPartyIdAreas.json cannot be read from Git Repository. Please check your GitRepository" -ForegroundColor Red
            break
        }
    }
    else {
        try {
            $thirdpartyfobs = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\ThirdPartyIdAreas.json") -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Host "ThirdPartyIdAreas.json cannot be read. Please check file $($ENV:APPDATA)\NavToGit\ThirdPartyIdAreas.json" -ForegroundColor Red
            break
        }
    }

    $Functions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\Functions.ps1"
    . $Functions
     

    Get-ConfigFileIntegrity -config $config

    if (-not $useConfig -eq "") {
        Get-ObjectMembers $config | ForEach-Object {
            if (($_.key -like $useConfig)) {
                $config.active = $_.key
                $useConfig = $_.key
                $config | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json")
                Write-Host "NAVToGit configuration $useConfig is now active!" -ForegroundColor Cyan
                $activated = $true
            }
        }
        if (-not $activated) {
            Write-Host "Configuration ""$useConfig"" has not been found. Aborting..."
            break
        }
    }

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Started Export with configuration $($config.active)" -ForegroundColor Cyan

    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    [int]$finsqlversion = Get-ChildItem $finsqlPath | ForEach-Object { $_.VersionInfo.ProductVersion } | ForEach-Object { $_.SubString(0, $_.IndexOf(".")) }

    if ($finsqlversion -lt 7) {
        if ([Environment]::Is64BitProcess) {
            write-warning "Old NAV Version: Switching to 32-bit PowerShell."
            $modulepath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "NAVToGit.psm1"
            if ($null -eq $customFilter ) {
                [String]$Startx86 = "Import-Module '" + $modulepath + "' -DisableNameChecking; Export-FromNAVToGit"
            }
            else {
                [String]$Startx86 = "Import-Module '" + $modulepath + "' -DisableNameChecking; Export-FromNAVToGit -customFilter '$customFilter'"
            }
            
            &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NoProfile -Command $Startx86
            break
        }
        Start-Export-Nav6 -config $config -thirdpartyfobs $thirdpartyfobs -customFilter $customFilter
        
        
    }
    else {
        if ($config.$($config.active).Authentication -like "UserPassword") {
            if ($Credential -eq $null) {
                Write-Host "Following credentials were found: $($credential.UserName) / $($credential.GetNetworkCredential().Password). Please enter valid credentials.."
                $Credential = $host.ui.PromptForCredential("Need credentials for NAV Instance.", "Please enter username and password.", "", "")
            }
            if (-not ($null -eq $Credential)) {
                Start-Export -config $config -credential $Credential -thirdpartyfobs $thirdpartyfobs -customFilter $customFilter
            }
            else {
                Write-Host "No credentials have been provided. Aborting..." -ForegroundColor Red
            }
        }
        else {
            Get-ThirdPartyAreaJson -config $config -thirdpartyfobs $thirdpartyfobs -customFilter $customFilter
        }
    }    

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Export finished. You can close this Window." -ForegroundColor Green
}