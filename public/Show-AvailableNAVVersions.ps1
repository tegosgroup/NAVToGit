function Show-AvailableNAVVersions {
    $AllVersions = @{ }
    $AllVersionsSorted = [ordered]@{ }
    $Drives = Get-PSDrive -PSProvider 'FileSystem'
    $NAVFolders = @('Program Files (x86)\Microsoft Dynamics NAV',
        'Program Files (x86)\Microsoft Dynamics 365 Business Central',
        'ProgramData\NavContainerHelper',
        'ProgramData\BcContainerHelper'
    )
    $UserPaths = @()
    $Drives | ForEach-Object { 
        $currDrive = $_.Root
        $NAVFolders | ForEach-Object { 
            $currPath = Join-Path $currDrive $_ 
            if (Test-Path $currPath) {
                $UserPaths += @($currPath)
            }
        } 
    }

    $NAVPaths = Get-ChildItem -Filter "finsql.exe" -Recurse -ErrorAction SilentlyContinue -Path $UserPaths

    foreach ($path in $NAVPaths) {
        $NAVVersion = Get-ChildItem $path.FullName | ForEach-Object { $_.VersionInfo.FileVersion } | ForEach-Object { $_.SubString(0, $_.LastIndexOf(".")) }
        if (-not $AllVersions.Get_Item($NAVVersion)) {
            $AllVersions.Add($NAVVersion, $path.FullName)
        }
    }
    
    foreach ($ver in ($AllVersions.Keys | Sort-Object { [Version] $_ })) {
        $AllVersionsSorted.Add($ver,$AllVersions.Get_Item($ver))
    }
    
    return $AllVersionsSorted
}