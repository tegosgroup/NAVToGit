function Show-AvailableNAVVersions {
    $AllVersions = @{ }
    $AllVersionsSorted = [ordered]@{ }
    $UserPaths = @('C:\Program Files (x86)\Microsoft Dynamics NAV', `
            'C:\Program Files (x86)\Microsoft Dynamics 365 Business Central', `
            'C:\ProgramData\NavContainerHelper')

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