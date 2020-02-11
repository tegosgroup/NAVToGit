# NavToGit Powershell Module
A powershell module to synchronize NAV Databases(6.0-14.0) with Git.

## Installation

Use Git or any other Git Client to clone this repository.

```powershell
git clone https://github.com/tegosGroup/NAVToGit.git
```
Afterwards import the module with powershell.

```powershell
Import-Module <path to your local git repo>\DynamicsNAVToGit.psm1
```

## First Setup
Setup your first config with the GUI. These settings will configure the NAV Database <-> Git source connection.
```powershell
Show-NavToGitGui
```

![content](https://user-images.githubusercontent.com/60692534/73855139-ec1bd380-4833-11ea-855d-02998ea515ab.png)

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

#### Set-ActiveNAVToGitConnection *-ConfigToActivate <ConfigName>*
The entered configuration in the parameter `ConfigToActivate` will be stored in the json as active. 
Starting the command without parameter will show all available configurations and call you to select one.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
