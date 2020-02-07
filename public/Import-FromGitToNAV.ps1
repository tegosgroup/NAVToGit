function Import-FromGitToNAV {
    param (
        $useConfig,
        [switch]$compile,
        [parameter(DontShow)]
        [switch]$dark
    )
    try {
        $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
        $guiconfig = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json") -ErrorAction Stop | ConvertFrom-Json
        $thirdpartyfobs = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\ThirdPartyIdAreas.json") -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Host "JSON cannot be read. Please check configfile." -ForegroundColor Red
        break
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

    if ($compile) {
        $config.$($config.active).CompileObjects = $true;
    }


    $GUIFunctions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\gui\ImportObjectsList.ps1"
    . $GUIFunctions

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Started Import with configuration $($config.active)" -ForegroundColor Cyan

    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    [int]$finsqlversion = Get-ChildItem $finsqlPath | ForEach-Object { $_.VersionInfo.ProductVersion } | ForEach-Object { $_.SubString(0, $_.IndexOf(".")) }

    if ($finsqlversion -lt 7) {
        if ([Environment]::Is64BitProcess) {
            Write-Warning "Old NAV Version: Switching to 32-bit PowerShell."
            $modulepath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "DynamicsNAVToGit.psm1"
            [String]$Startx86 = "Import-Module '" + $modulepath + "' -DisableNameChecking; Import-FromGitToNAV"
            &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NoProfile -command $Startx86
            break
        }
        $nav6 = $true
        Start-Export-Nav6 -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs
    }
    else {
        if ($config.$($config.active).Authentication -like "UserPassword") {
            $Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "")
            Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs -credential $Credential
        }
        else {
            Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs
        }
        $nav6 = $false;
    }
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Export finished" -ForegroundColor Cyan

    $databaseFolderPath = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active
    $gitFolderPath = Get-Item $config.$($config.active).GitPath
    $list = Compare-Folders -databaseFolder $databaseFolderPath -gitFolder $gitFolderPath -nav6 $nav6
    $databaseName = $config.$($config.active).DatabaseName
    $servername = $config.$($config.active).SQLServerName

    if ([long]$list.Count -gt 0) {
        while ($true) {
            $decision = Read-Host "$(Get-Date -Format "HH:mm:ss") | Found $($list.Count) changed objects. Enter (a) to apply all changed objects, (s) to select the objects you want to import or (c) to cancel this operation"
            if ($decision -eq "a") {
                [System.Collections.Generic.List[String]]$selectedObjectsList = Set-Nav-Changes -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -list $list -nav6 $nav6 -credential $Credential -config $config
                break
            }
            elseif ($decision -eq "s") {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Collecting changed object information"
                Open-ObjectList -git $gitFolderPath -temp $databaseFolderPath -CompareToolPath ($guiconfig.CompareToolPath) -CompareToolParam ($guiconfig.CompareToolParameter) -dark:$dark
                Initialize-GridViewWithPsObjects -dataList (Show-Changed-Objects -databasePath $databaseFolderPath -gitPath $gitFolderPath) -dark:$dark
                [System.Collections.Generic.List[String]]$selectedObjectsList = Show-Dialog
                if (0 -eq $selectedObjectsList.Count) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | No objects have been selected for Import"
                    break
                }
                else {
                    [System.Collections.Generic.List[String]]$selectedObjectsList = Set-Nav-Changes -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -list $selectedObjectsList  -nav6 $nav6 -credential $Credential -config $config
                    break
                }
            }
            elseif ($decision -eq "c") {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | The action was aborted" -ForegroundColor Red
                break
            }
        }
        if ($config.$($config.active).CompileObjects -and -not $nav6){
            Set-ObjectsCompiled -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -selectedObjectsList $selectedObjectsList  -nav6 $nav6 -credential $Credential -config $config
        } elseif (($config.$($config.active).CompileObjects -and $nav6)) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Start compiling $($selectedObjectsList.Count) objects" -ForegroundColor Cyan
            $failedObjectsList = Set-Nav6ObjectsCompiled -DatabaseName $databaseName -SelectedObjectsList $selectedObjectsList            
            if ($failedObjectsList.length -gt 0) {
                $regex = [Regex]::new("([^\\]*).*\s([0-9]*).txt")
                $failedObjectsList | ForEach-Object {
                    $match = $regex.Matches($_)[0]
                    $Type = $match.Groups[1].Value
                    [long]$Id = $match.Groups[2].Value
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | Error while trying to compile $Type $Id" -ForegroundColor Red
                    $selectedObjectsList.Remove($_) > $null
                }
                $selectedObjectsList | ForEach-Object {
                    $match = $regex.Matches($_)[0]
                    $Type = $match.Groups[1].Value
                    [long]$Id = $match.Groups[2].Value
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | Successfully compiled $Type $Id." -ForegroundColor Green
                }
            }
        }
    }
    else {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | No import or delete in database needed - git and database are in sync"
    }
    
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Removing tempfolder " + $config.$($config.active).TempFolder) -ForegroundColor Cyan
    Remove-Item -Recurse -Force -Path (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active)
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Import finished. You can close this window.") -ForegroundColor Green
}