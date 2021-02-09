function Start-Export-Nav6 {
    Param(
        [switch]$skipRobocopy,
        $config,
        $thirdpartyfobs,
        $customFilter
    )
    $GitRepo = (Join-Path -Path (Get-Item $config.$($config.active).GitPath) -ChildPath "").Trim("\")

    $CultureConverter = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\CultureConverter.ps1"
    . $CultureConverter
    $TempRepo = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active
    

    $databaseName = $config.$($config.active).DatabaseName

    if (Test-Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json")) {
        $RepoConfig = Get-Content -Raw -Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json") -ErrorAction Stop | ConvertFrom-Json
        $RepoCulture = [System.Globalization.CultureInfo]::new($RepoConfig.RepoCulture).LCID
    }
    else {
        $SystemCulture = Get-Culture
        $RepoCulture = $SystemCulture.LCID
    }

    
    if (!(Test-Path $TempRepo)) {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating tempfolder " + $TempRepo) -ForegroundColor Cyan
        mkdir $TempRepo > $null
    } 
    else {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Cleaning tempfolder " + $TempRepo) -ForegroundColor Cyan
        Remove-Item -Path (Join-Path -Path $TempRepo -ChildPath "*") -Recurse
    }

    Import-Module (Join-Path -Path ((Get-Item $PSScriptRoot).Parent.FullName) -ChildPath "lib/COMNavConnector.dll")
    if ((Find-NavisionProcess -DatabaseName $databaseName) -eq 0) {
        $modulePath = Join-Path -Path ((Get-Item $PSScriptRoot).Parent.FullName) -ChildPath "lib/COMNavConnector.dll"

        $useCustomFilter = -Not ($null -eq $customFilter)
        $objectTypes = @("Table", "Form", "Report", "Dataport", "Codeunit", "XMLport", "MenuSuite", "Page")
        if ($useCustomFilter) {
            $map = Convert-CustomStringToNewNavFilters -customFilter $customFilter
            foreach ($key in $map.Keys) {
                $value = $map[$key]
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Started exporting ${key}s with filter '$value'"
                Start-Job $ExportNav6 -Name $key -ArgumentList $key, $TempRepo, $databaseName, $modulePath, $value > $null
            }
        }
        else {
            $filter = "ID=$(Get-NoThirdPartyFilter -thirdpartyfobs $thirdpartyfobs)"
            foreach ($type in $objectTypes) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Started exporting $($type)s"
                Start-Job $ExportNav6 -Name $type -ArgumentList $type, $TempRepo, $databaseName, $modulePath, $filter > $null
            }
        }
    
        While (Get-Job -State "Running") {
            Start-Sleep -seconds 2
        }

        Remove-Job *

        Receive-Job *

        $AtLeastOneObjectTypeFailedToExport = $false
        Get-ChildItem $TempRepo -Attributes Directory | ForEach-Object {
            $DirectoryInfo = Get-ChildItem $_.FullName | Measure-Object
            If ($DirectoryInfo.Count -eq 0) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | No objects of type '$_' from database exported. Invalid license or not all ThirdPartyIdAreas defined?" -ForegroundColor Red
                $AtLeastOneObjectTypeFailedToExport = $true
            }
        }

        if ($AtLeastOneObjectTypeFailedToExport) {
            $decision = Read-Host "$(Get-Date -Format "HH:mm:ss") | Do you want to continue the operation? This may result in DATA LOSS![y/n]"
            if (-not ($decision -eq "y")) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Operation has been aborted." -ForegroundColor Red
                break
            }
        }

        Write-Host "$(Get-Date -Format "HH:mm:ss") | Splitting files" -ForegroundColor Cyan
        Split-Objects -TempRepo $TempRepo -types $objectTypes

        if (Is-LanguageDifferent -valueCulture $RepoCulture) {
            Convert-Culture -config $config -repoCulture $RepoCulture -objectTypes $objectTypes
        }

        if (-Not ($skipRobocopy)) {
            if ($useCustomFilter) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Moving objects to Git-Repository" -ForegroundColor Cyan
                Move-FilteredObjects -Source $TempRepo -Destination $GitRepo
            }
            else {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Executing Robocopy" -ForegroundColor Cyan
                Copy-Robocopy -GitRepo $GitRepo -TempRepo $TempRepo -objectTypes $objectTypes -EnableThirdPartyFobExport $false
            }
        }
    }
    else {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | The specified Navision Classic Client instance could not be found! finsql.exe has to be running!" -ForegroundColor Red
    }

    if ($config.$($config.active).EnableThirdPartyFobExport) {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | The following third-party areas have to be exported manually:" -ForegroundColor Yellow
        $ThirdPartyFilterList = Get-ThirdPartyFilterList -thirdpartyfobs $thirdpartyfobs
        $ThirdPartyFilterList.Keys | ForEach-Object {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | $_.fob : $($ThirdPartyFilterList.Get_Item($_))"
        }
    }
}

function Move-FilteredObjects {
    Param(
        $Source,
        $Destination
    )
    Get-ChildItem -Path $Source | ForEach-Object {
        Copy-Item $_.FullName -Destination $Destination -Exclude @("navcommandresult.txt", "*.zup") -Recurse -Force
    }
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Removing tempfolder " + $Source) -ForegroundColor Cyan
    Remove-Item -Recurse -Path $Source
}

function Show-ChangesInApplication {
    Param(
        $gitPath,
        $databasePath,
        $CompareToolPath,
        $CompareToolParam,
        $filename
    )
    $file1 = Join-Path -Path $databasePath -ChildPath $filename
    $file2 = Join-Path -Path $gitPath -ChildPath $filename
    $file = $CompareToolPath
    if (Test-Path $file) {
        $argumentlist = $CompareToolParam.Replace("%1", """$file1""").Replace("%2", """$file2""")
        Start-Process -FilePath $file -ArgumentList $argumentlist
    }
    else {
        Write-Host "Compare tool could not be found. Please check gui.config.json" -ForegroundColor Red
    }
}

function Start-Export {

    Param(
        $config,
        $customFilter,
        $thirdpartyfobs,
        [pscredential]$credential,
        [switch]$skipRobocopy
    )

    $CultureConverter = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\CultureConverter.ps1"
    . $CultureConverter

    $GitRepo = (Join-Path -Path (Get-Item $config.$($config.active).GitPath) -ChildPath "").trim("\")
    $TempRepo = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active
    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    $sqlServername = $config.$($config.active).SQLServerName
    $databaseName = $config.$($config.active).DatabaseName

    if (Test-Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json")) {
        $RepoConfig = Get-Content -Raw -Path (Join-Path -Path $config.$($config.active).GitPath -ChildPath "RepoConfig.json") -ErrorAction Stop | ConvertFrom-Json
        $RepoCulture = [System.Globalization.CultureInfo]::new($RepoConfig.RepoCulture).LCID
    }
    else {
        $SystemCulture = Get-Culture
        $RepoCulture = $SystemCulture.LCID
    }
    
    if (!(Test-Path $TempRepo)) {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating tempfolder " + $TempRepo) -ForegroundColor Cyan
        mkdir $TempRepo > $null
    }
    else {
        Write-Host("$(Get-Date -Format "HH:mm:ss") | Cleaning tempfolder " + $TempRepo) -ForegroundColor Cyan
        Remove-Item -Path (Join-Path -Path $TempRepo -ChildPath "*") -Recurse
    }
    
    $filter = ""
    $useCustomFilter = -Not ($null -eq $customFilter)
    $objectTypes = @("Codeunit", "Page", "Table", "Report", "Query", "XMLport", "MenuSuite")
    if ($useCustomFilter) {
        $objectWithFilters = Convert-CustomStringToNewNavFilters -customFilter $customFilter
        foreach ($key in $objectWithFilters.Keys) {
            $value = $objectWithFilters[$key]
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Started exporting ${key}s with filter '$value'"
            $filter = "Type=$key;$value"
            Start-Job $Export -Name $type -ArgumentList $key, $filter, $TempRepo, $finsqlPath, $sqlServername, $databaseName, $credential > $null
        }
    }
    else {
        $filter = Get-NoThirdPartyFilter -thirdpartyfobs $thirdpartyfobs
        foreach ($type in $objectTypes) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Started exporting $($type)s"
            Start-Job $Export -Name $type -ArgumentList $type, "Type=$type;ID=$filter", $TempRepo, $finsqlPath, $sqlServername, $databaseName, $credential > $null
        }
        if ($config.$($config.active).EnableThirdPartyFobExport) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Started exporting Third-Party fobs"
            $ThirdPartyFilterList = Get-ThirdPartyFilterList -thirdpartyfobs $thirdpartyfobs
            $ThirdPartyFilterList.Keys | ForEach-Object {
                $filter = $ThirdPartyFilterList.Get_Item($_)
                Start-Job $ExportFob -Name $_ -ArgumentList $_, $filter, $TempRepo, $finsqlPath, $sqlServername, $databaseName, $credential > $null
            }
        }
    }
    While (Get-Job -State "Running") {
        Start-Sleep -seconds 2
    }

    Remove-Job *

    [String]$logFile = Get-Content (Join-Path -Path $TempRepo -ChildPath "navcommandresult.txt")
    if (-not $logFile.contains("successfully")) {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | Error while trying to Export:`n"(Get-Content $logFile.Substring($logFile.LastIndexOf(":") - 1)) -ForegroundColor Red
        break
    }

    $ErrorLogs = Get-ChildItem -Filter "*.log" -ErrorAction SilentlyContinue -Path $TempRepo
    if (-not ($null -eq $ErrorLogs)) {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | Error while trying to Export:" -ForegroundColor Red
        $ErrorLogs | ForEach-Object {
            Write-Host $(Get-Content $_.FullName) -ForegroundColor Red
        }
        break
    }

    Write-Host "$(Get-Date -Format "HH:mm:ss") | Splitting files" -ForegroundColor Cyan
    Split-Objects -TempRepo $TempRepo -types $objectTypes
    
    if (Is-LanguageDifferent -valueCulture $RepoCulture ) {
        Convert-Culture -config $config -repoCulture $RepoCulture -objectTypes $objectTypes
    }

    if (-Not ($skipRobocopy)) {
        if ($useCustomFilter) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Moving objects to Git-Repository" -ForegroundColor Cyan
            Move-FilteredObjects -Source $TempRepo -Destination $GitRepo
        }
        else {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | Executing Robocopy" -ForegroundColor Cyan
            Copy-Robocopy -GitRepo $GitRepo -TempRepo $TempRepo -objectTypes $objectTypes -EnableThirdPartyFobExport $config.$($config.active).EnableThirdPartyFobExport
        }
    }
}

function Get-ObjectMembers {
    Param(
        [PSCustomObject]$obj
    )
    $obj | Get-Member -MemberType NoteProperty | ForEach-Object {
        $key = $_.Name
        [PSCustomObject]@{key = $key; value = $obj."$key" }
    }
}

function Get-ThirdPartyFilterList {
    Param(
        $thirdpartyfobs
    )

    $ThirdPartyFilterList = @{ }

    Get-ObjectMembers $thirdpartyfobs | ForEach-Object {
        $filter = ""
        $area = @{ }

        $_.value | ForEach-Object {
            if (-not $area.ContainsKey($_.from)) {
                $area.Add($_.from, $_.to)
            }
        }

        $area.Keys | ForEach-Object {
            $filter = "${filter}$_..$($area.Get_Item($_))|"
        }    
        $filter = $filter.Trim("|");

        $ThirdPartyFilterList.Add($_.key, $filter)
    }
    return $ThirdPartyFilterList
}

function Get-NoThirdPartyFilter {
    Param(
        $thirdpartyfobs
    )

    $NoThirdPartyFilter = ""
    $areas = @{ }
    Get-ObjectMembers $thirdpartyfobs | ForEach-Object {
        $_.value | ForEach-Object {
            if (-not $areas.ContainsKey($_.from)) {
                $areas.Add($_.from, $_.to)
            }
        }
    }

    $areas.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
        $NoThirdPartyFilter = "${NoThirdPartyFilter}$($_.Key-1)|$($_.Value+1).."
    }

    return "1..${NoThirdPartyFilter}2000000000"
}

$Export = {
    param(
        [string]$type,
        $filter,
        $TempRepo,
        $finsqlPath,
        $sqlServername,
        $databaseName,
        [pscredential]$credential
    )
    
    $logFile = Join-Path(Get-Item $TempRepo).FullName "$type-Log.log"
    if (-Not (Test-Path (Join-Path(Get-Item $TempRepo).FullName "$type"))) {
        New-Item -Path $TempRepo -Name $type.ToLower() -ItemType Directory -Force
    }
    $exportFile = Join-Path(Get-Item $TempRepo).FullName "$type\Export.txt"
    $finzup = Join-Path(Get-Item $TempRepo).FullName "$databaseName-$type-$(Get-Date -Format HHmmss).zup"

    if ($null -eq $credential) {
        Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$exportFile, servername=$sqlServername, filter=$filter, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$logFile" -Wait
    }
    else {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$exportFile, servername=$sqlServername, filter=$filter, database=$databaseName, ntauthentication=no, username=$username, password=$password, id=$finzup, logfile=$logFile" -Wait
    }
}

$ExportFob = {
    param(
        [string]$ThirdParty,
        $idfilter,
        $TempRepo,
        $finsqlPath,
        $sqlServername,
        $databaseName,
        [pscredential]$credential
    )
    
    $logFile = Join-Path(Get-Item $TempRepo).FullName "$ThirdParty-Log.log"
    if (-Not (Test-Path (Join-Path(Get-Item $TempRepo).FullName "fob"))) {
        New-Item -Path $TempRepo -Name "fob" -ItemType Directory -Force
    }
    $exportFile = Join-Path(Get-Item $TempRepo).FullName "fob\$ThirdParty.fob"
    $finzup = Join-Path(Get-Item $TempRepo).FullName "$databaseName.zup"

    if ($null -eq $credential) {
        Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$exportFile, servername=$sqlServername, filter=ID=$idfilter, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$logFile" -Wait
    }
    else {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$exportFile, servername=$sqlServername, filter=ID=$idfilter, database=$databaseName, ntauthentication=no, username=$username, password=$password, id=$finzup, logfile=$logFile" -Wait
    }

    if ((Get-Item($exportFile)).Length -eq 940) {
        Remove-Item $exportFile
    }
}

$ExportNav6 = {
    Param(
        [string]$type,
        $TempRepo,
        $databaseName,
        $modulePath,
        $customFilter
    )
    Import-Module $modulePath
    Get-NavisionObjects -DatabaseName $databaseName -TempFolder $TempRepo -ObjectType $type -ObjectFilter $customFilter
}

function Split-Objects {
    Param(
        $TempRepo,
        $types
    )
    Import-Module (Join-Path -Path ((Get-Item $PSScriptRoot).Parent.FullName) -ChildPath "lib/SplitNavObjects.dll")
    foreach ($type in $types) {
        Split-NavObjectFile -Path $TempRepo -Type $type
    }
}
function Copy-Robocopy {
    Param(
        $GitRepo,
        $TempRepo,
        $objectTypes,
        [bool]$EnableThirdPartyFobExport
    )
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Moving files to Git-Repository " + $GitRepo) -ForegroundColor Cyan
    foreach ($type in $objectTypes) {
        $typeFolderTemp = Join-Path -Path $TempRepo -ChildPath $type.ToLower()
        $typeFolderGit = Join-Path -Path $GitRepo -ChildPath $type.ToLower()
        Robocopy $typeFolderTemp $typeFolderGit /mov /mir > $null
    }
    if ($EnableThirdPartyFobExport) {
        $typeFolderTemp = Join-Path -Path $TempRepo -ChildPath 'fob'
        $typeFolderGit = Join-Path -Path $GitRepo -ChildPath 'fob'
        Robocopy $typeFolderTemp $typeFolderGit /mov > $null
    }
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Removing tempfolder " + $TempRepo) -ForegroundColor Cyan
    Remove-Item -Recurse -Path $TempRepo
}
function Compare-Dirs {
    param(
        [string]$type,
        $databaseFolder,
        $gitFolder
    )
    $folderDatabase = Get-ChildItem $databaseFolder | ForEach-Object { Get-FileHash -Path $_.FullName -Algorithm SHA1 }
    
    $folderGit = Get-ChildItem $gitFolder | ForEach-Object { Get-FileHash -Path $_.FullName -Algorithm SHA1 }    

    $hashtable = New-Object System.Collections.Generic.HashSet[string]
    try {
        Compare-Object -ReferenceObject $folderDatabase -DifferenceObject $folderGit  -Property hash -PassThru | ForEach-Object {
            $hashtable.Add("$($type.ToLower())\" + (Get-Item -Path $_.Path).Name) > $null
        }
    }
    catch {
        if ($null -eq $folderDatabase) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | No objects of type '$type' from database exported. Possible error? No $type objects have been compared!" -ForegroundColor Red
            if (Test-Path (Join-Path -Path $databaseFolder -ChildPath "..\$type-Log.log")) {
                $logFile = Join-Path -Path $databaseFolder -ChildPath "..\$type-Log.log"
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Error Message: "(Get-Content $logFile) -ForegroundColor Red
            }
        }
        if ($null -eq $folderGit) {
            Write-Host "$(Get-Date -Format "HH:mm:ss") | No objects of type '$type' found in git-folder. Possible error? No $type objects have been compared!" -ForegroundColor Red
        }
    }
    return $hashtable
}

function Compare-Folders {
    Param(
        $databaseFolder,
        $gitFolder,
        [bool]$nav6
    )
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Compare started" -ForegroundColor Cyan

    if ($nav6) {
        $types = @("Table", "Form", "Report", "Dataport", "Codeunit", "XMLport", "MenuSuite", "Page") 
    }
    else {
        $types = @("Codeunit", "Page", "Table", "Report", "Query", "XMLport", "MenuSuite")
    }
    $all = New-Object System.Collections.Generic.HashSet[string]
    foreach ($type in $types) {
        $value = [System.Collections.Generic.HashSet[string]](Compare-Dirs -type $type -databaseFolder "$databaseFolder\$($type.ToLower())" -gitFolder "$gitFolder\$($type.ToLower())")
        if (-Not ($value -eq $null)) {
            $all.UnionWith($value)
        }
    }
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Compare finished" -ForegroundColor Cyan
    return $all
}

function Set-Nav-Changes {
    Param(
        $databaseName,
        $servername,
        $finsqlPath,
        [System.Collections.Generic.List[String]]$list,
        [bool]$nav6,
        [pscredential]$credential,
        $config
    )
    $TempRepo = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active
    $finzup = Join-Path($TempRepo) "$databaseName.zup"

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

    if ($nav6) {
        Import-Module (Join-Path -Path ((Get-Item $PSScriptRoot).Parent.FullName) -ChildPath "lib/COMNavConnector.dll") 
    }
    
    $listlength = $list.Count

    $count = 1
    for ($i = 0; $i -lt $list.Count; $i++) {
        $item = $list[$i]
        $path = Join-Path -Path $config.$($config.active).GitPath -ChildPath $item
        [string]$filename = Split-Path -Path $path -leaf
        if (-not $filename.EndsWith("fob")) {
            [Long]$id = $filename.Substring($filename.IndexOf(" ") + 1, 10)
            $type = $filename.Substring(0, $filename.IndexOf(" "))
        }
        else {
            $type = $filename
            $id = ""
        }
        $log = Join-Path -Path $config.$($config.active).TempFolder -ChildPath "$($config.$($config.active).DatabaseName) - import.log"
        if (-Not (Test-Path $path)) {
            if ($nav6) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | $type $id has been deleted in git repository. Please remove the object manually!" -ForegroundColor Red
            }
            else {
                if ($null -eq $credential) {
                    Start-Process -FilePath $finsqlPath -ArgumentList "command=DeleteObjects, filter=Type=$type;ID=$id, servername=$servername, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$log, synchronizeschemachanges=force" -Wait > $null
                }
                else {
                    $username = $credential.UserName
                    $password = $credential.GetNetworkCredential().Password        
                    Start-Process -FilePath $finsqlPath -ArgumentList "command=DeleteObjects, filter=Type=$type;ID=$id, servername=$servername, database=$databaseName, ntauthentication=no, username=$username, password=$password, id=$finzup, logfile=$log, synchronizeschemachanges=force" -Wait > $null
                }
                if (Test-Path $log) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Error while trying to delete $type ${id}:" -ForegroundColor Red
                    Write-Host (Get-Content($log)) -ForegroundColor White
                }
                else {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Deleted $type $id" -ForegroundColor Red
                    $list.RemoveAt($i) > $null
                    $i--
                }
            }
        }
        else {
            if (Is-LanguageDifferent -valueCulture $RepoCulture ) {
                Convert-FileCulture -objectPath $path -repoCulture $RepoCulture -config $config
                $path = Join-Path -Path $TempRepo -ChildPath $item
            }
            if ($nav6) {
                if ((Set-NavisionObjectText -DatabaseName $databaseName -FilePath $path) -eq 0) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Imported $type $id" -ForegroundColor Green
                }
                else {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Error while trying to Import $type ${id}." -ForegroundColor Red
                    $list.RemoveAt($i) > $null
                    $i--
                }
            }
            else {
                if ($null -eq $credential) {
                    Start-Process -FilePath $finsqlPath -ArgumentList "command=ImportObjects, file=$path, servername=$servername, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$log, importaction=overwrite" -Wait > $null
                }
                else {
                    $username = $credential.UserName
                    $password = $credential.GetNetworkCredential().Password        
                    Start-Process -FilePath $finsqlPath -ArgumentList "command=ImportObjects, file=$path, servername=$servername, database=$databaseName, ntauthentication=no, username=$username, password=$password, id=$finzup, logfile=$log, importaction=overwrite" -Wait > $null
                }
                if (Test-Path $log) {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Error while trying to Import $type ${id}:" -ForegroundColor Red
                    Write-Host (Get-Content($log)) -ForegroundColor White
                    $list.RemoveAt($i) > $null
                    $i--
                }
                else {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Imported $type $id" -ForegroundColor Green
                }
            }            
        }
        $count++
    }
    return $list
}

function Get-FobAndDeleteTxt {
    Param(
        $config,
        $FobFolderPath,
        [System.Collections.Generic.List[String]]$list,
        [bool]$nav6,
        [pscredential]$credential
    )

    $databaseName = $config.$($config.active).DatabaseName
    $servername = $config.$($config.active).SQLServerName
    $finsqlPath = Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"
    $finzup = Join-Path(Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active) "$databaseName.zup"

    $filterHashMap = [ordered]@{ }
    $toDeleteHashMap = [ordered]@{ }

    $list | ForEach-Object {
        $type = [regex]::Match($_, "(.*)\\").Groups[1].Value
        if (Test-Path (Join-Path -Path (Join-Path -Path $config.$($config.active).Tempfolder -ChildPath $config.active) -ChildPath $_)) {
            if (-not $filterHashMap.Get_Item($type)) {
                $filterHashMap.Add($type, [string][regex]::Match($_, "0+(.*)\.txt").Groups[1].Value)
            }
            else {
                $filterHashMap.$type = $filterHashMap.$type + ("|" + [string][regex]::Match($_, "0+(.*)\.txt").Groups[1].Value)
            }
        }
        else {
            if (-not $toDeleteHashMap.Get_Item($type)) {
                $toDeleteHashMap.Add($type, [string][regex]::Match($_, "0+(.*)\.txt").Groups[1].Value)
            }
            else {
                $toDeleteHashMap.$type = $toDeleteHashMap.$type + ("|" + [string][regex]::Match($_, "0+(.*)\.txt").Groups[1].Value)
            }
        }
    }

    if ($null -eq $FobFolderPath) {
        $FobFolderPath = Get-FolderPathDialog -Description "Select path where the delta fob(s) are going to be created"
    }
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Using path '$FobFolderPath' for delta fob(s)."    
    
    $gitCommitId = git -C (Get-Item $config.$($config.active).GitPath) log -n1 --format="%h"

    $filter = ""
    $filterHashMap.Keys | ForEach-Object {
        if ($nav6) {
            $filter = $filter + "type=" + $_ + ";id=" + $filterHashMap.Get_Item($_) + "`n"
        }
        else {
            if ($filterHashMap.Get_Item($_).Length -ge 512) {
                $objectType = $_
                $objectArray = $filterHashMap.Get_Item($_).Split("|")
                $objectArrayInChunks = for ($i = 0; $i -lt $objectArray.Length; $i += 70) { , ($objectArray[$i .. ($i + 69)]) }

                $count = 1
                $objectArrayInChunks | ForEach-Object {
                    Write-Host "$(Get-Date -Format "HH:mm:ss") | Writing fob $($count)/$($objectArrayInChunks.Length) for object type $($objectType)"
                    $filter = "type=" + $objectType + ";id=" + [system.String]::Join("|", $_)
                    Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$FobFolderPath\$($config.active)-Delta-$gitCommitId-$objectType-$count.of.$($objectArrayInChunks.Length).fob, servername=$servername, filter=$filter, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$logFile" -Wait
                    $count++
                }
            }
            else {
                $filter = "type=" + $_ + ";id=" + $filterHashMap.Get_Item($_)
                Write-Host "$(Get-Date -Format "HH:mm:ss") | Writing fob for object type $($_)"
                Start-Process -FilePath $finsqlPath -ArgumentList "command=exportobjects, file=$FobFolderPath\$($config.active)-Delta-$gitCommitId-$_.fob, servername=$servername, filter=$filter, database=$databaseName, ntauthentication=yes, id=$finzup, logfile=$logFile" -Wait
            }        
        }
    }
    if ($nav6) {
        Write-Host "$(Get-Date -Format "HH:mm:ss") | Writing summary txt for objects which have been created or changed"
        New-Item -Path "$FobFolderPath\$($config.active)-Delta-$gitCommitId-toChangeOrCreate.txt" -ItemType File -Value $filter -Force > $null        
    }

    $ToDeleteFileText = ""
    $toDeleteHashMap.Keys | ForEach-Object {
        $ToDeleteFileText = $ToDeleteFileText + "type=" + $_ + ";id=" + $toDeleteHashMap.Get_Item($_) + "`n"
    }
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Writing summary txt for objects which have been deleted"
    if ($ToDeleteFileText -eq "") {
        New-Item -Path "$FobFolderPath\$($config.active)-Delta-$gitCommitId-toDelete.txt" -ItemType File -Value "Nothing to be deleted" -Force > $null
    }
    else {
        New-Item -Path "$FobFolderPath\$($config.active)-Delta-$gitCommitId-toDelete.txt" -ItemType File -Value $ToDeleteFileText -Force > $null
    }
}

function Set-ObjectsCompiled {
    param(
        $config,
        $databaseName,
        $servername,
        $finsqlPath,
        $selectedObjectsList,
        $nav6,
        [pscredential]$credential
    )
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Start compiling" -ForegroundColor Cyan
    $log = Join-Path -Path $config.$($config.active).TempFolder -ChildPath "$($config.$($config.active).DatabaseName) - compile.log"
    $regex = [Regex]::new("([^\\]*).*\s([0-9]*).txt")
    $count = 0
    $listlength = $selectedObjectsList.Count
    if ($null -eq $credential) {
        foreach ($item in $selectedObjectsList) {
            if (Test-Path $log) {
                Remove-Item $log
            }
            $count++
            $match = $regex.Matches($item)[0]
            $filterType = $match.Groups[1].Value
            $filterId = $match.Groups[2].Value
            $filter = "type=" + $filterType + ";id=" + $filterId
            Start-Process -FilePath $finsqlPath -ArgumentList "command=compileobjects, filter=$filter, servername=$servername, database=$databaseName, ntauthentication=yes, synchronizeschemachanges=yes, logfile=$log" -Wait
            if (Test-Path $log) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Error while trying to compile $filtertype ${filterId}:" -ForegroundColor Red
                Write-Host (Get-Content($log)) -ForegroundColor White
                continue
            }
            else {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Successfully compiled $filtertype $filterId." -ForegroundColor Green
            }
        }          
    }
    else {
        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password
        foreach ($item in $selectedObjectsList) {
            $count++
            $match = $regex.Matches($item)[0]
            $filterType = $match.Groups[1].Value
            $filterId = $match.Groups[2].Value
            $filter = "type=" + $filterType + ";id=" + $filterId            
            Start-Process -FilePath $finsqlPath -ArgumentList "command=compileobjects, filter=$filter, servername=$servername, database=$databaseName, ntauthentication=no, username=$username, password=$password  synchronizeschemachanges=yes, logfile=$log" -Wait
            if (Test-Path $log) {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Error while trying to compile $filtertype ${filterId}:" -ForegroundColor Red
                Write-Host (Get-Content($log)) -ForegroundColor White
                continue
            }
            else {
                Write-Host "$(Get-Date -Format "HH:mm:ss") | [$count/$listlength] Successfully compiled $filtertype $filterId." -ForegroundColor Green
            }
        }          
    }
}

function Get-ConfigFileIntegrity {
    Param(
        $config
    )
    if (($null -eq (Get-ObjectMembers $config).length)) {
        Write-Host "JSON cannot be read - No configuration has been set up. Please check configfile $($ENV:APPDATA)\NavToGit\config.json" -ForegroundColor Red
        break
    }    
    if (-not (Test-Path -Path (Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe"))) {
        Write-Host ("finsql.exe could not be found in $($finsqlPath) - please check RTC Path in current configuration") -ForegroundColor Red
        break
    }
}

<#Returns wether a file was changed (0), deleted (-1), created (1) or on function error -2 #>
function Resolve-FileChangesForImport {
    Param(
        $gitPath,
        $databasePath,
        $relativeFilePath
    )

    $gitExists = Test-Path -Path (Join-Path -Path $gitPath -ChildPath $relativeFilePath)
    $databaseExists = Test-Path -Path (Join-Path -Path $databasePath -ChildPath $relativeFilePath)

    if ($gitExists -eq $true -and $databaseExists -eq $true) {
        return 0
    }
    elseif ($gitExists -eq $true -and $databaseExists -eq $false) {
        return 1
    }
    elseif ($gitExists -eq $false -and $databaseExists -eq $true) {
        return -1
    }
    else {
        return -2
    }



}

function Show-Changed-Objects {
    param(
        $databasePath,
        $gitPath,
        [switch]$GitToDatabase
    )
    $GridViewList = New-Object System.Collections.Generic.List[PsCustomObject]
    
    $regexDate = [Regex]::new("Date=([\d][\d]\.[\d][\d]\.[\d][\d]);")
    $regexTime = [Regex]::new("Time=([\d][\d]\:[\d][\d]\:[\d][\d]);")
    $regexVersion = [Regex]::new("(?<=Version List=)(.*?);")
    $regexName = [Regex]::new("(?<=OBJECT\s\S+\s\S+\s)(.*?){")

    if ($GitToDatabase) {
        $ObjectNotInGit = "DELETE"
        $ObjectNotInDatabase = "CREATE"
    }
    else {
        $ObjectNotInGit = "CREATE"
        $ObjectNotInDatabase = "DELETE"
    }

    $list | ForEach-Object {
        $objectfilename = $_
        $objectchangetype = "CHANGE"
        $objecttype = [regex]::Match($_, "(.*)\\").Groups[1].Value
        $objectid = [int]$_.SubString($_.IndexOf(" "), 11)
        try {
            $objectDatabase = Get-Content (Join-Path -Path $databasePath -ChildPath $_) -ErrorAction SilentlyContinue
            $objectDatabaseName = $regexName.Match($objectDatabase).Groups[1].Value
            $objectDatabaseVersion = $regexVersion.Match($objectDatabase).Groups[1].Value
            $objectDatabaseDatetime = $regexDate.Match($objectDatabase).Groups[1].Value + " " + $regexTime.Match($objectDatabase).Groups[1].Value
        }
        catch {
            $objectDatabaseDatetime = "-"
            $objectDatabaseVersion = "-"
            $objectDatabaseName = "-"
            $objectchangetype = $ObjectNotInDatabase
        }
        try {
            $objectGit = Get-Content (Join-Path -Path $gitPath -ChildPath $_) -ErrorAction SilentlyContinue
            $objectGitName = $regexName.Match($objectGit).Groups[1].Value
            $objectGitVersion = $regexVersion.Match($objectGit).Groups[1].Value
            $objectGitDatetime = $regexDate.Match($objectGit).Groups[1].Value + " " + $regexTime.Match($objectGit).Groups[1].Value            
        }
        catch {
            $objectGitDatetime = "-"
            $objectGitVersion = "-"
            $objectGitName = "-"
            $objectchangetype = $ObjectNotInGit
        }

        $changedobject = New-Object -TypeName psobject
        
        $changedobject | Add-Member -MemberType NoteProperty -Name "Action" -Value $objectchangetype   
        $changedobject | Add-Member -MemberType NoteProperty -Name "Object Type" -Value $objecttype    
        $changedobject | Add-Member -MemberType NoteProperty -Name "Object ID" -Value $objectid
        $changedobject | Add-Member -MemberType NoteProperty -Name "Database Object Name" -Value $objectDatabaseName
        $changedobject | Add-Member -MemberType NoteProperty -Name "Git Object Name" -Value $objectGitName
        $changedobject | Add-Member -MemberType NoteProperty -Name "Database Date/Time" -Value $objectDatabaseDatetime
        $changedobject | Add-Member -MemberType NoteProperty -Name "Git Date" -Value $objectGitDatetime
        $changedobject | Add-Member -MemberType NoteProperty -Name "Database Version" -Value $objectDatabaseVersion
        $changedobject | Add-Member -MemberType NoteProperty -Name "Git Version" -Value $objectGitVersion
        $changedobject | Add-Member -MemberType NoteProperty -Name "Object File Name" -Value $objectfilename

        $GridViewList.Add($changedobject)        
    }
    return $GridViewList
}

function Convert-CustomStringToNewNavFilters {
    Param(
        $customFilter
    )
    $dictionary = @{ }
        
    [Regex]::Matches($customFilter, "(?i)(codeunit|dataport|form|menusuite|page|query|report|table|xmlport)(?>=)(.*?)(?>;|)(?i)(?=codeunit=|dataport=|form=|menusuite=|page=|query=|report=|table=|xmlport=|\Z)") | ForEach-Object {
        if ($_.Success -and -not ($_.Groups[2].Value -eq "")) {
            $dictionary.Add($_.Groups[1].Value, $_.Groups[2].Value)
        }
    }
    return $dictionary
}

function Convert-CustomStringToFilenameList {
    Param(
        $customFilter
    )
    $dictionary = Convert-CustomStringToNewNavFilters -customFilter $customFilter

    $pathlist = [System.Collections.ArrayList]@()
    foreach ($objectType in $dictionary.keys) {
        $filterString = $dictionary.Item($objectType)
        [Regex]::Matches($filterString, "id=(.+?)(?>;|$)", [Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object {
            if ($_.Success -and -not ($_.Groups[1].Value -eq "")) {
                
                $IdFilterArray = $_.Groups[1].Value.Split("|")
                foreach ($Filter in $IdFilterArray) {
                    if ($Filter.Contains("..")) {
                        if ($Filter.StartsWith("..")) {
                            try {
                                [int]$max = $Filter.TrimStart("..")
                                for ($i = 0; $i -le $max; $i++) {
                                    $pathlist.Add("$objectType\$objectType " + ([String]$i).PadLeft(10, "0") + ".txt")>null
                                }
                            }
                            catch {
                                Write-Host "Given Id-Range is not valid: $Filter" -ForegroundColor Red
                            }                
                        }
                        elseif ($Filter.EndsWith("..")) {
                            try {
                                [int] $min = $Filter.TrimEnd("..")
                                for ($i = $min; $i -lt 2000000000; $i++) {
                                    $pathlist.Add("$objectType\$objectType " + ([String]$i).PadLeft(10, "0") + ".txt")>null
                                }
                            }
                            catch {
                                Write-Host "Given Id-Range is not valid: $Filter" -ForegroundColor Red
                            }                          
                        }
                        else {
                            try {
                                [int] $min = $Filter.Substring(0, $Filter.IndexOf(".."))
                                [int] $max = $Filter.Substring($Filter.IndexOf("..") + 2, $Filter.Length - $Filter.IndexOf("..") - 2)              
                                for ($i = $min; $i -le $max; $i++) {
                                    $pathlist.Add("$objectType\$objectType " + ([String]$i).PadLeft(10, "0") + ".txt")>null
                                }
                            }
                            catch {
                                Write-Host "Given Id-Range is not valid: $Filter" -ForegroundColor Red
                            }
                        }
                    }
                    else {
                        $pathlist.Add("$objectType\$objectType " + $Filter.PadLeft(10, "0") + ".txt")>null
                    }
                }

            }
        }
    }
    return $pathlist
}

$CallConverter = {
    param (
        $type,
        $repoCulture,
        $TempRepo,
        $CultureConverter
    )    
    . $CultureConverter

    $folder = Get-ChildItem (Join-Path -Path $TempRepo -ChildPath $type)
    foreach ($object in $folder) {
        $contentPath = (Join-Path -Path $TempRepo -ChildPath "$type\$object")
        $content = [System.IO.File]::ReadAllText($contentPath, [System.Text.Encoding]::GetEncoding(850))
        [System.IO.File]::WriteAllText($contentPath, (Convert-TextLanguage -languageId $repoCulture -content $content -toNavision $false), [System.Text.Encoding]::GetEncoding(850))
    }
}

function Convert-Culture {
    param(
        $config,
        $repoCulture,
        $objectTypes
    )
    $TempRepo = Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active

    $repoCultureDisplayName = [System.Globalization.CultureInfo]::new($repoCulture).DisplayName
    
    $CultureConverter = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "private\CultureConverter.ps1"
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Start converting to language:  $repoCultureDisplayName" -ForegroundColor Cyan
    foreach ($type in $objectTypes) {
        Start-Job $CallConverter -Name $type -ArgumentList $type, $repoCulture, $TempRepo, $CultureConverter > $null
    }

    While (Get-Job -State "Running") {
        Start-Sleep -seconds 2
    }
    Remove-Job *
    
    Write-Host "$(Get-Date -Format "HH:mm:ss") | Finished converting language" -ForegroundColor Cyan
}

function Convert-FileCulture {
    param(
        $config,
        $repoCulture,
        $objectPath
    )

    $content = [System.IO.File]::ReadAllText($objectPath, [System.Text.Encoding]::GetEncoding(850))
    $newObjectPath = Join-Path -Path (Join-Path -Path $config.$($config.active).TempFolder -ChildPath $config.active) -ChildPath $item
    [System.IO.File]::WriteAllText($newObjectPath, (Convert-TextLanguage -languageId $repoCulture -content $content -toNavision $true), [System.Text.Encoding]::GetEncoding(850))
}

function Get-FolderPathDialog {
    param(
        [String]$Description
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ("" -eq $Description) {
        $FolderBrowser.Description = "Please select a path."
    }
    else {
        $FolderBrowser.Description = $Description
    }
    $FolderBrowser.ShowDialog() > $null
    $Path = $FolderBrowser.SelectedPath
    $FolderBrowser.Dispose()
    return $Path
}