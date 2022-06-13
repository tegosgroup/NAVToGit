function Get-FobForDelivery {
    param (
        $useConfig,
        $OutputPath,
        [pscredential]$Credential,
        [parameter(DontShow)]
        [switch]$dark
    )
    try {
        $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
        $guiconfig = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json") -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Host "JSON cannot be read. Please check configfile." -ForegroundColor Red
        break
    }

    if (Test-Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "ThirdPartyIdAreas.json")){
        try {
            $thirdpartyfobs = Get-Content -Raw -Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "ThirdPartyIdAreas.json") -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Host "ThirdPartyIdAreas.json cannot be read from Git Repository. Please check your GitRepository" -ForegroundColor Red
            break
        }
    } else {
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
    
    $GUIFunctions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\gui\ImportObjectsList.ps1"
    . $GUIFunctions

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Started getting fob(s) for delivery with configuration $($config.active)" -ForegroundColor Cyan

    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    [int]$finsqlversion = Get-ChildItem $finsqlPath | ForEach-Object { $_.VersionInfo.ProductVersion } | ForEach-Object { $_.SubString(0, $_.IndexOf(".")) }

    if ($finsqlversion -lt 7) {
        if ([Environment]::Is64BitProcess) {
            Write-Warning "Old NAV Version: Switching to 32-bit PowerShell."
            $modulepath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "NAVToGit.psm1"
            [String]$Startx86 = "Import-Module '" + $modulepath + "' -DisableNameChecking; Import-FromGitToNAV"
            &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NoProfile -command $Startx86
            break
        }
        $nav6 = $true
        Start-Export-Nav6 -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs
    }
    else {
        if ($config.$($config.active).Authentication -like "UserPassword") {
            if($Credential -eq $null){
                $Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "")
            }
            Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs -credential $Credential
        }
        else {
            Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs
        }
        $nav6 = $false;
    }
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Export finished" -ForegroundColor Cyan

    $gitCommitId = git -C (Get-Item $config.$($config.active).GitPath) log -n1 --format="%h"
    $decision = Write-Host "$(Get-Date -Format "HH:mm:ss") | Comparing database with git commit '$gitCommitId'."
    $list = Compare-Folders -databaseFolder (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active) -gitFolder (Get-Item $config.$($config.active).GitPath) -nav6 $nav6

    if ([long]$list.Count -gt 0) {
        while ($true) {
            $decision = Read-Host "$(Get-Date -Format "HH:mm:ss") | Found $($list.Count) changed objects in database compared to git commit '$gitCommitId'. Enter (a) to write all changed objects to fob, (s) to select the objects you want to write or (c) to cancel this operation"
            if ($decision -eq "a") {
                Get-FobAndDeleteTxt -config $config -FobFolderPath $OutputPath -list $list -nav6 $nav6 -credential $Credential
                break
            }
            elseif ($decision -eq "s") {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Collecting changed object information"
                Open-ObjectList -git (Get-Item $config.$($config.active).GitPath) -temp (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active) -CompareToolPath ($guiconfig.CompareToolPath) -CompareToolParam ($guiconfig.CompareToolParameter) -dark:$dark -getFobs
                Initialize-GridViewWithPsObjects -dataList (Show-Changed-Objects -databasePath (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active) -gitPath (Get-Item $config.$($config.active).GitPath)) -dark:$dark -getFobs
                [System.Collections.Generic.List[String]]$selectedObjectsList = Show-Dialog
                if (0 -eq $selectedObjectsList.Count) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | No objects have been selected for fob creation"
                    break
                }
                else {
                    Get-FobAndDeleteTxt -config $config -FobFolderPath $OutputPath -list $selectedObjectsList -nav6 $nav6 -credential $Credential
                    break
                }
            }
            elseif ($decision -eq "c") {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | The action was aborted" -ForegroundColor Red
                break
            }
        }
    }
    else {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | No changed objects to export - git and database are the same"
    }
    
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Removing tempfolder " + (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active)) -ForegroundColor Cyan
    Remove-Item -Recurse -Force -Path (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active)
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Writing fob(s) for delivery completed. You can close this window.") -ForegroundColor Green
}