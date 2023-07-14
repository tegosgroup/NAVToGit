function Import-FromGitToNAV {
    param (
        $useConfig,
        $customFilter,
        [switch]$compile,
        [PSCredential]$credential,
        [switch]$noInput,
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

    if ($compile) {
        $config.$($config.active).CompileObjects = $true;
    }


    $GUIFunctions = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\gui\ImportObjectsList.ps1"
    . $GUIFunctions

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Started Import with configuration $($config.active)" -ForegroundColor Cyan

    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    [int]$finsqlversion = Get-ChildItem $finsqlPath | ForEach-Object { $_.VersionInfo.ProductVersion } | ForEach-Object { $_.SubString(0, $_.IndexOf(".")) }

    $databaseFolderPath = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active
    $gitFolderPath = Get-Item $config.$($config.active).GitPath
    $databaseName = $config.$($config.active).DatabaseName
    $servername = $config.$($config.active).SQLServerName

    if (-not $customFilter -eq "") {
        if ($finsqlversion -lt 7) {
            if ([Environment]::Is64BitProcess) {
                Write-Warning "Old NAV Version: Switching to 32-bit PowerShell."
                $modulepath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "NAVToGit.psm1"
                [String]$Startx86 = "Import-Module '" + $modulepath + "' -DisableNameChecking; Import-FromGitToNAV -customFilter '$customFilter'"
                &"$env:WINDIR\syswow64\windowspowershell\v1.0\powershell.exe" -NoProfile -command $Startx86
                break
            }
            $nav6 = $true
        }

        if (Test-Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json")) {
            $RepoConfig = Get-Content -Raw -Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json") -ErrorAction Stop | ConvertFrom-Json
            $RepoCulture = [System.Globalization.CultureInfo]::new($RepoConfig.RepoCulture).LCID
        }
        else {
            $SystemCulture = Get-Culture
            $RepoCulture = $SystemCulture.LCID
        }
    
        $CultureConverter = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\CultureConverter.ps1"
        . $CultureConverter

        [System.Collections.Generic.List[String]]$list = Convert-CustomStringToFilenameList -customFilter $customFilter

        if ([long]$list.Count -gt 0) {
            for ($i = 0; $i -lt $list.Count; $i++) {
                $item = $list[$i]
                $path = Join-Path -Path $config.$($config.active).GitPath -ChildPath $item
                if (-not(Test-Path $path)) {
                    $list.RemoveAt($i) > $null                            
                    $i--
                }
            }
            
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Found $($list.Count) files out of given custom filter:"
            Format-List -InputObject $list
            if($noInput.IsPresent){
                Write-Host "Running NavToGit without user interfaction. Use (y) to import all files.."
                $decision = "y"
            } else{
                $decision = Read-Host "Enter (y) to import the shown files or any other key to cancel this operation"
            }
            if ($decision -eq "y") {
                if (-not (Test-Path -Path $databaseFolderPath)) {
                    New-Item -ItemType Directory -Path $databaseFolderPath >null
                }
                $log = Join-Path -Path $config.$($config.active).TempFolder -ChildPath "$($config.$($config.active).DatabaseName) - import.log"

                if ($config.$($config.active).Authentication -like "UserPassword" -and (-not $nav6)) {
                    if($credential -eq $null){
                        Write-Host "Following credentials were found: $($credential.UserName) / $($credential.GetNetworkCredential().Password). Please enter valid credentials.."
                        $credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "")
                    }
                }
                $listCount = $list.Count
                $counter = 1
                for ($i = 0; $i -lt $list.Count; $i++) {
                    $item = $list[$i]
                    $path = Join-Path -Path $config.$($config.active).GitPath -ChildPath $item                     
                    
                    if (Is-LanguageDifferent -valueCulture $RepoCulture ) {
                        if(-not (Test-Path -Path (Split-Path (Join-Path -Path $databaseFolderPath -ChildPath $item) -Parent))){
                            New-Item -ItemType Directory -Path (Split-Path (Join-Path -Path $databaseFolderPath -ChildPath $item) -Parent) >null
                        }                        
                        Convert-FileCulture -objectPath $path -repoCulture $RepoCulture -config $config
                        $path = Join-Path -Path $databaseFolderPath -ChildPath $item
                    }

                    if ($nav6) {
                        Import-Module (Join-Path -Path ((Get-Item $PSScriptRoot).Parent.FullName) -ChildPath "lib/COMNavConnector.dll")
                        if ((Set-NavisionObjectText -DatabaseName $databaseName -FilePath $path) -eq 0) {
                            Write-Host "$(Get-Date -Format "HH:mm:ss") | [$($counter)/$($listCount)] Imported $item" -ForegroundColor Green
                        }
                        else {
                            Write-Host "$(Get-Date -Format "HH:mm:ss") | [$($counter)/$($listCount)] Error while trying to Import $item." -ForegroundColor Red
                            $list.RemoveAt($i) > $null
                            $i--
                        }
                    }
                    else {                      
                        if ($null -eq $credential) {
                            Start-Process -FilePath $finsqlPath -ArgumentList "command=ImportObjects, file=$path, servername=$servername, database=$databaseName, ntauthentication=yes, logfile=$log, importaction=overwrite" -Wait > $null
                        }
                        else {
                            $username = $credential.UserName
                            $password = $credential.GetNetworkCredential().Password        
                            Start-Process -FilePath $finsqlPath -ArgumentList "command=ImportObjects, file=$path, servername=$servername, database=$databaseName, ntauthentication=no, username=$username, password=$password, logfile=$log, importaction=overwrite" -Wait > $null
                        }

                        if (Test-Path $log) {
                            Write-Host "$(Get-Date -Format "HH:mm:ss") | [$($counter)/$($listCount)] Error while trying to Import ${item}:" -ForegroundColor Red
                            Write-Host (Get-Content($log)) -ForegroundColor White
                            $list.RemoveAt($i) > $null                            
                            $i--
                        }
                        else {
                            Write-Host "$(Get-Date -Format "HH:mm:ss") | [$($counter)/$($listCount)] Imported ${item}" -ForegroundColor Green
                        }
                    }
                    $counter++                    
                }

                if ($config.$($config.active).CompileObjects -and $nav6 -and $list.Count -ne 0) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | Start compiling $($list.Count) objects" -ForegroundColor Cyan
                    $failedObjectsList = Set-Nav6ObjectsCompiled -DatabaseName $databaseName -SelectedObjectsList $list
                    $regex = [Regex]::new("([^\\]*).*\s([0-9]*).txt")
                    if ($failedObjectsList.length -gt 0) {                        
                        $failedObjectsList | ForEach-Object {
                            $match = $regex.Matches($_)[0]
                            $Type = $match.Groups[1].Value
                            [long]$Id = $match.Groups[2].Value
                            Write-Host "$(Get-Date -Format "HH:mm:ss") | Error while trying to compile $Type $Id" -ForegroundColor Red
                            $list.Remove($_) > $null
                        }                        
                    }
                    $list | ForEach-Object {
                        $match = $regex.Matches($_)[0]
                        $Type = $match.Groups[1].Value
                        [long]$Id = $match.Groups[2].Value
                        Write-Host "$(Get-Date -Format "HH:mm:ss") | Successfully compiled $Type $Id." -ForegroundColor Green
                    }
                }
                elseif ($config.$($config.active).CompileObjects -and (-not $nav6)-and $list.Count -ne 0) {
                    Set-ObjectsCompiled -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -selectedObjectsList $list  -nav6 $false -credential $credential -config $config
                }
            }
            else {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | The action was aborted" -ForegroundColor Red
                $config.$($config.active).CompileObjects = $false
            }
            
        }
        else {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Custom Filter could not be read correctly."
        }
    }
    else {        
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
                if ($null -eq $credential) {
                    $Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password.", "", "")
                }
                if (-not ($null -eq $Credential)) {
                    Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs -credential $Credential
                }
                else {
                    Write-Host "No credentials have been provided. Aborting..." -ForegroundColor Red
                    break
                }
            }
            else {
                Start-Export -skipRobocopy -config $config -thirdpartyfobs $thirdpartyfobs
            }
            $nav6 = $false;
        }
        Write-Host "$(Get-Date -Format "HH:mm:ss") | Export finished" -ForegroundColor Cyan

        $list = Compare-Folders -databaseFolder $databaseFolderPath -gitFolder $gitFolderPath -nav6 $nav6

        if ([long]$list.Count -gt 0) {            
            while ($true) {
                if($noInput.IsPresent){
                    Write-Host "Running NavToGit without user interfaction. Use (a) to apply all changes.."
                    $decision = "a"
                } else{
                    $decision = Read-Host "$(Get-Date -Format "HH:mm:ss") | Found $($list.Count) changed objects. Enter (a) to apply all changed objects, (s) to select the objects you want to import or (c) to cancel this operation"
                }                
                if ($decision -eq "a") {
                    [System.Collections.Generic.List[String]]$selectedObjectsList = Set-Nav-Changes -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -list $list -nav6 $nav6 -credential $Credential -config $config
                    break
                }
                elseif ($decision -eq "s") {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | Collecting changed object information"
                    Open-ObjectList -git $gitFolderPath -temp $databaseFolderPath -CompareToolPath ($guiconfig.CompareToolPath) -CompareToolParam ($guiconfig.CompareToolParameter) -dark:$dark
                    Initialize-GridViewWithPsObjects -dataList (Show-Changed-Objects -databasePath $databaseFolderPath -gitPath $gitFolderPath -GitToDatabase) -dark:$dark
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
                    $config.$($config.active).CompileObjects = $false
                    break
                }
            }
            if ($config.$($config.active).CompileObjects -and -not $nav6) {
                Set-ObjectsCompiled -databaseName $databaseName -servername $servername -finsqlPath $finsqlPath -selectedObjectsList $selectedObjectsList  -nav6 $nav6 -credential $Credential -config $config
            }
            elseif (($config.$($config.active).CompileObjects -and $nav6)) {
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
    }

    if (Test-Path -Path $databaseFolderPath) {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Removing tempfolder " + $config.$($config.active).TempFolder) -ForegroundColor Cyan
        Remove-Item -Recurse -Force -Path $databaseFolderPath
    }
    
    
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Import finished. You can close this window.") -ForegroundColor Green
}