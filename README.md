# NavToGit Powershell Module
A powershell module to synchronize NAV Databases (6.0-14.0) with Git.

## Installation

The easiest way to install the script is by using our following install script.
This will download the latest release of the NAVToGit script and install it into your Powershell user modules directory. Afterwards the module will be available in every Powershell instance and also update itself automatically whenever a new release has been published.

Start **Powershell ISE** and copy this script, which downloads the current InstallScript from GitHub, and executes it:
```powershell
# NAVToGit Install Script

$uri = "https://raw.githubusercontent.com/tegosGroup/NAVToGit/master/.install/InstallScript.ps1"
$installScript = [Scriptblock]::Create((Invoke-WebRequest -Uri $uri).Content)
Invoke-Command -ScriptBlock $installScript
```
**Alternatively**, if you do not want to blindly download and execute scripts from the internet, you can copy the complete InstallScript into **Powershell ISE**:
<details><summary><i>Click here for the complete InstallScript</i></summary>
<p>
  
```powershell
# NAVToGit Install Script

Write-Host("$(Get-Date -Format "HH:mm:ss") | Starting NAVToGit Module installation") -ForegroundColor White
$approval = Read-Host ("$(Get-Date -Format "HH:mm:ss") | Do you want to continue? [y/n]")
if ($approval -ne "y") {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Cancelled NAVToGit module installation") -ForegroundColor Red
    break
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $obj = Invoke-WebRequest -Uri "https://api.github.com/repos/tegosGroup/NAVToGit/releases/latest" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
}
catch {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | No connection to Github.") -ForegroundColor Red
    break
}
$temp = Join-Path -Path $env:TEMP -ChildPath "NavToGitUpdate"
$downloadFile = Join-Path -Path $temp -ChildPath "update.zip"

Remove-Item -Path $temp -Recurse -Force -ErrorAction SilentlyContinue > $null
New-Item -path $temp -ItemType Directory > $null

Write-Host("$(Get-Date -Format "HH:mm:ss") | Downloading latest release...") -ForegroundColor Cyan
Invoke-WebRequest -Uri $obj.zipball_url -OutFile $downloadFile

Write-Host("$(Get-Date -Format "HH:mm:ss") | Extracting download zip") -ForegroundColor White
Expand-Archive -Path $downloadFile -DestinationPath $temp -Force

$userPath = "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments))\WindowsPowerShell\Modules\NAVToGit"
if (-not (Test-Path -Path $userPath)) {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating directory C:$userPath") -ForegroundColor Cyan
    New-Item -Path $userPath -ItemType Directory > $null
}

Write-Host("$(Get-Date -Format "HH:mm:ss") | Moving new files") -ForegroundColor Cyan
Robocopy (Get-ChildItem $temp)[0].FullName $userPath /mov /mir /xd .git > $null

Write-Host("$(Get-Date -Format "HH:mm:ss") | Deleting temp folder $temp") -ForegroundColor White
Remove-Item -Path $temp -Recurse -Force

$approval = Read-Host ("$(Get-Date -Format "HH:mm:ss") | Do you want to create a desktop shortcut to the NAVToGitGui? [y/n]")
if ($approval -eq "y") {
    Write-Host("$(Get-Date -Format "HH:mm:ss") | Creating Desktop Shortcut for GUI") -ForegroundColor White
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop))\Show-NAVToGitGui.lnk")
    $Shortcut.TargetPath = "$env:WINDIR\system32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-command Show-NAVToGitGui"
    $Shortcut.Save()
}

Write-Host("$(Get-Date -Format "HH:mm:ss") | NAVToGit Module has been installed.") -ForegroundColor Green
```

</p>
</details>

## First Setup
Setup your first config with the GUI. These settings will configure the NAV Database <-> Git source connection.
```powershell
Show-NavToGitGui
```
![image](https://user-images.githubusercontent.com/58514804/74413498-cf892800-4e3f-11ea-8af9-dade45505e2d.png)

Config Parameter |  Description
------------ | -------------
NAV Version / RTC Path  | All NAV versions installed on the computer are displayed and can be selected. In addition, the corresponding path to the finsql.exe of the version is shown in the brackets behind.
SQL Server Name | Specifies the used SQL Server, e.g. HOSTNAME\SERVERNAME.
Database Name | The name of the NAV database.
Tempfolder | For both import and export, a temporary folder is required in which the objects are saved for comparasion with the specified git directory and deleted afterwards. Here you can choose where the folder will be created at runtime. By default it is in the %temp% folder.
Git Path | Here you can specify the folder of the desired git directory in which the objects are located.
Authentication | The choice is between Windows or UserPassword authentication.
Enable Third Party Fob Export | **Default:** false <br/> With this checkbox checked, you say that you want to export and import the areas of the ThirdPartyAreas.json. When exporting, the corresponding areas are exported as Fob and saved in an explicit Fob folder. On import, the ranges are imported as fob. 
Compile Objects |  **Default:** false <br/> By checking this Box the imported objects will be compiled if possible.

## Usage
The Module supports the following commands:

#### Show-NAVToGitGui *-dark*
The GUI will be opened. With parameter `dark` the Gui will be opened in dark mode.

#### Import-FromGitToNav *-useConfig <ConfigName> -compile*
Imports selected different objects from git repository to the NAV database.
The parameter `useConfig` specifies the configuration which will be used. With given switch `compile` the imported objects will be compiled, if possible.

#### Export-FromNAVToGit *-customFilter <Filter> -useConfig <ConfigName>*
Without entering any parameter all objects of the active configuration will be exported. 
The parameter `customFilter` hands over the filter of the objects which you want to export. Example: `Export-FromNAVToGit -customFilter “codeunit=ID=2..10;modified=No;table=ID=10..20”`
The parameter `useConfig` specifies the configuration which will be used.

#### Show-AvailableNAVVersions
All available Nav Versions with path to the related RoleTailoredClient will be shown.

#### Set-ActiveNAVToGitConfiguration *-useConfig <ConfigName>*
The entered configuration in the parameter `useConfig` will be stored in the json as active. 
Starting the command without parameter will show all available configurations and call you to select one.

#### Update-NAVToGit
Searches the GitHub repository for new releases and prompts for update if a newer version is found.

## Further information
You can find further information in our [Wiki](https://github.com/tegosGroup/NAVToGit/wiki)

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
