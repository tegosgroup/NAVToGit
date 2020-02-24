$Global:newMode = $false
function Open-MainMenu {

    $config = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json") -ErrorAction Stop | ConvertFrom-Json
    $guiconfig = Get-Content -Raw -Path (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json") -ErrorAction Stop | ConvertFrom-Json

    $Global:editing = $false
    $Global:dark = $guiconfig.DarkMode

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $currentSettingsItems = @()

    $NavToGit = New-Object system.Windows.Forms.Form
    $NavToGit.ClientSize = '810,585'
    $NavToGit.text = "Dynamics Nav To Git Integration"
    $NavToGit.TopMost = $false
    $NavToGit.DataBindings.DefaultDataSourceUpdateMode = 0
    $NavToGit.MaximizeBox = $false
    $NavToGit.FormBorderStyle = 'Fixed3D'
    if (($guiconfig.MainWindowPosition.x -In [System.Windows.Forms.SystemInformation]::VirtualScreen.Left .. [System.Windows.Forms.SystemInformation]::VirtualScreen.Right) -and ($guiconfig.MainWindowPosition.y -In [System.Windows.Forms.SystemInformation]::VirtualScreen.Top .. ([System.Windows.Forms.SystemInformation]::VirtualScreen.Bottom - 40))) {
        $NavToGit.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
        $NavToGit.DesktopLocation = [System.Drawing.Point]::new($guiconfig.MainWindowPosition.x,$guiconfig.MainWindowPosition.y)
    } else {
        $NavToGit.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    }
    $NavToGit.KeyPreview = $true

    $ImportButton = New-Object system.Windows.Forms.Button
    $ImportButton.BackColor = "#FF1E90FF"
    $ImportButton.text = "&Import (Git >> Database)"
    $ImportButton.width = 370
    $ImportButton.height = 60
    $ImportButton.location = New-Object System.Drawing.Point(20, 435)
    $ImportButton.Font = 'Segoe UI,12, style=Bold'
    $ImportButton.Add_MouseClick( { Open-ImportMessageBox })

    $ExportButton = New-Object system.Windows.Forms.Button
    $ExportButton.BackColor = "#FF90EE90"
    $ExportButton.text = "E&xport (Database >> Git)"
    $ExportButton.width = 370
    $ExportButton.height = 60
    $ExportButton.location = New-Object System.Drawing.Point(420, 435)
    $ExportButton.Font = 'Segoe UI,12, style=Bold'
    $ExportButton.Add_MouseClick( { Open-ExportMessageBox })

    $SelectExportButton = New-Object system.Windows.Forms.Button
    $SelectExportButton.BackColor = "#FF32CD32"
    $SelectExportButton.text = "Se&lective Export... (Database >> Git)"
    $SelectExportButton.width = 370
    $SelectExportButton.height = 60
    $SelectExportButton.location = New-Object System.Drawing.Point(420, 505)
    $SelectExportButton.Font = 'Segoe UI,12, style=Bold'
    $SelectExportButton.Add_MouseClick( { Open-SelectiveExportMessageBox })

    $FobForDeliveryButton = New-Object system.Windows.Forms.Button
    $FobForDeliveryButton.BackColor = "#FF87CEFA"
    $FobForDeliveryButton.text = "Get Fobs For Delivery"
    $FobForDeliveryButton.width = 370
    $FobForDeliveryButton.height = 60
    $FobForDeliveryButton.location = New-Object System.Drawing.Point(20, 505)
    $FobForDeliveryButton.Font = 'Segoe UI,12, style=Bold'
    $FobForDeliveryButton.Add_MouseClick( {  Open-GetFobMessageBox })

    $CurrentConfigurationGroupBox = New-Object system.Windows.Forms.Groupbox
    $CurrentConfigurationGroupBox.height = 400
    $CurrentConfigurationGroupBox.width = 770
    $CurrentConfigurationGroupBox.text = "Current Configuration"
    $CurrentConfigurationGroupBox.location = New-Object System.Drawing.Point(20, 20)
    $CurrentConfigurationGroupBox.Font = 'Segoe UI,10'

    $currentConfigComboBox = New-Object system.Windows.Forms.ComboBox
    $currentConfigComboBox.text = "comboBox"
    $currentConfigComboBox.width = 640
    $currentConfigComboBox.height = 20
    $currentConfigComboBox.location = New-Object System.Drawing.Point(20, 30)
    $currentConfigComboBox.Font = 'Segoe UI,10'
    $currentConfigComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $currentConfigComboBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $currentConfigComboBox.Add_SelectedIndexChanged( { Invoke-ConfigComboboxIndexChange -config $config -NavToGit $NavToGit } )
    $currentConfigComboBox.Add_DrawItem( { Show-ComboBox -combobox $currentConfigComboBox } )

    $RTCPathLabel = New-Object system.Windows.Forms.Label
    $RTCPathLabel.text = "NAV Version / RTC Path:"
    $RTCPathLabel.AutoSize = $true
    $RTCPathLabel.width = 25
    $RTCPathLabel.height = 10
    $RTCPathLabel.location = New-Object System.Drawing.Point(20, 73)
    $RTCPathLabel.Font = 'Segoe UI,10'

    $SQLServerNameLabel = New-Object system.Windows.Forms.Label
    $SQLServerNameLabel.text = "SQL Server Name:"
    $SQLServerNameLabel.AutoSize = $true
    $SQLServerNameLabel.width = 25
    $SQLServerNameLabel.height = 10
    $SQLServerNameLabel.location = New-Object System.Drawing.Point(20, 108)
    $SQLServerNameLabel.Font = 'Segoe UI,10'

    $DatabaseNameLabel = New-Object system.Windows.Forms.Label
    $DatabaseNameLabel.text = "Database Name:"
    $DatabaseNameLabel.AutoSize = $true
    $DatabaseNameLabel.width = 25
    $DatabaseNameLabel.height = 10
    $DatabaseNameLabel.location = New-Object System.Drawing.Point(20, 143)
    $DatabaseNameLabel.Font = 'Segoe UI,10'

    $TempfolderLabel = New-Object system.Windows.Forms.Label
    $TempfolderLabel.text = "Tempfolder:"
    $TempfolderLabel.AutoSize = $true
    $TempfolderLabel.width = 25
    $TempfolderLabel.height = 10
    $TempfolderLabel.location = New-Object System.Drawing.Point(20, 178)
    $TempfolderLabel.Font = 'Segoe UI,10'

    $GitPathLabel = New-Object system.Windows.Forms.Label
    $GitPathLabel.text = "Git Path:"
    $GitPathLabel.AutoSize = $true
    $GitPathLabel.width = 25
    $GitPathLabel.height = 10
    $GitPathLabel.location = New-Object System.Drawing.Point(20, 213)
    $GitPathLabel.Font = 'Segoe UI,10'

    $AuthenticationLabel = New-Object system.Windows.Forms.Label
    $AuthenticationLabel.text = "Authentication"
    $AuthenticationLabel.AutoSize = $true
    $AuthenticationLabel.width = 25
    $AuthenticationLabel.height = 10
    $AuthenticationLabel.location = New-Object System.Drawing.Point(20, 248)
    $AuthenticationLabel.Font = 'Segoe UI,10'

    $FobExportLabel = New-Object system.Windows.Forms.Label
    $FobExportLabel.text = "Enable Third Party Fob Export"
    $FobExportLabel.AutoSize = $true
    $FobExportLabel.width = 25
    $FobExportLabel.height = 10
    $FobExportLabel.location = New-Object System.Drawing.Point(20, 283)
    $FobExportLabel.Font = 'Segoe UI,10'

    $FobExportCheckBox = New-Object system.Windows.Forms.CheckBox
    $FobExportCheckBox.AutoSize = $false
    $FobExportCheckBox.width = 125
    $FobExportCheckBox.height = 20
    $FobExportCheckBox.location = New-Object System.Drawing.Point(220, 283)
    $FobExportCheckBox.Font = 'Segoe UI,10'

    $CompileLabel = New-Object system.Windows.Forms.Label
    $CompileLabel.text = "Compile Objects"
    $CompileLabel.AutoSize = $true
    $CompileLabel.width = 25
    $CompileLabel.height = 10
    $CompileLabel.location = New-Object System.Drawing.Point(20, 318)
    $CompileLabel.Font = 'Segoe UI,10'

    $CompileCheckBox = New-Object system.Windows.Forms.CheckBox
    $CompileCheckBox.AutoSize = $false
    $CompileCheckBox.width = 125
    $CompileCheckBox.height = 20
    $CompileCheckBox.location = New-Object System.Drawing.Point(220, 318)
    $CompileCheckBox.Font = 'Segoe UI,10'

    $EditButton = New-Object system.Windows.Forms.Button
    $EditButton.text = "&Edit"
    $EditButton.width = 70
    $EditButton.height = 30
    $EditButton.location = New-Object System.Drawing.Point(20, 353)
    $EditButton.Font = 'Segoe UI,10'
    $EditButton.Add_Click( { Invoke-ButtonEditClick -config $config -NavToGit $NavToGit } )

    $DeleteButton = New-Object system.Windows.Forms.Button
    $DeleteButton.text = "&Delete"
    $DeleteButton.width = 70
    $DeleteButton.height = 30
    $DeleteButton.location = New-Object System.Drawing.Point(100, 353)
    $DeleteButton.Font = 'Segoe UI,10'
    $DeleteButton.Add_Click( { Open-DeleteMessageBox -config $config -NavToGit $NavToGit })

    $NewButton = New-Object system.Windows.Forms.Button
    $NewButton.text = "&New"
    $NewButton.width = 70
    $NewButton.height = 30
    $NewButton.location = New-Object System.Drawing.Point(670, 28)
    $NewButton.Font = 'Segoe UI,10'
    $NewButton.Add_Click( { Invoke-ButtonNewClick -config $config -NavToGit $NavToGit -combobox $currentConfigComboBox -editingComponents $currentSettingsItems} )

    $RTCPathComboBox = New-Object system.Windows.Forms.ComboBox
    $RTCPathComboBox.width = 520
    $RTCPathComboBox.height = 20
    $RTCPathComboBox.location = New-Object System.Drawing.Point(220, 70)
    $RTCPathComboBox.Font = 'Segoe UI,10'
    $RTCPathComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $RTCPathComboBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $RTCPathComboBox.Add_DrawItem( { Show-ComboBox -combobox $RTCPathComboBox } )

    $SQLServerNameTextBox = New-Object system.Windows.Forms.TextBox
    $SQLServerNameTextBox.multiline = $false
    $SQLServerNameTextBox.width = 520
    $SQLServerNameTextBox.height = 20
    $SQLServerNameTextBox.location = New-Object System.Drawing.Point(220, 105)
    $SQLServerNameTextBox.Font = 'Segoe UI,10'

    $DatabaseNameTextBox = New-Object system.Windows.Forms.TextBox
    $DatabaseNameTextBox.multiline = $false
    $DatabaseNameTextBox.width = 520
    $DatabaseNameTextBox.height = 20
    $DatabaseNameTextBox.location = New-Object System.Drawing.Point(220, 140)
    $DatabaseNameTextBox.Font = 'Segoe UI,10'

    $TempFolderTextBox = New-Object system.Windows.Forms.TextBox
    $TempFolderTextBox.multiline = $false
    $TempFolderTextBox.width = 480
    $TempFolderTextBox.height = 20
    $TempFolderTextBox.location = New-Object System.Drawing.Point(220, 175)
    $TempFolderTextBox.Font = 'Segoe UI,10'

    $TempFolderSelectionButton = New-Object system.Windows.Forms.Button
    $TempFolderSelectionButton.text = "..."
    $TempFolderSelectionButton.width = 30
    $TempFolderSelectionButton.height = 25
    $TempFolderSelectionButton.location = New-Object System.Drawing.Point(710, 176)
    $TempFolderSelectionButton.Font = 'Segoe UI,10'
    $TempFolderSelectionButton.Add_Click( { Invoke-TempFolderSelectionClick -config $config -NavToGit $NavToGit } )

    $GitPathTextBox = New-Object system.Windows.Forms.TextBox
    $GitPathTextBox.multiline = $false
    $GitPathTextBox.width = 480
    $GitPathTextBox.height = 20
    $GitPathTextBox.location = New-Object System.Drawing.Point(220, 210)
    $GitPathTextBox.Font = 'Segoe UI,10'

    $GitFolderSelectionButton = New-Object system.Windows.Forms.Button
    $GitFolderSelectionButton.text = "..."
    $GitFolderSelectionButton.width = 30
    $GitFolderSelectionButton.height = 25
    $GitFolderSelectionButton.location = New-Object System.Drawing.Point(710, 211)
    $GitFolderSelectionButton.Font = 'Segoe UI,10'
    $GitFolderSelectionButton.Add_Click( { Invoke-GitFolderSelectionClick -config $config -NavToGit $NavToGit } )

    $AuthenticationComboBox = New-Object system.Windows.Forms.ComboBox
    $AuthenticationComboBox.text = "AuthenticationComboBox"
    $AuthenticationComboBox.width = 119
    $AuthenticationComboBox.height = 20
    $AuthenticationComboBox.location = New-Object System.Drawing.Point(220, 245)
    $AuthenticationComboBox.Font = 'Segoe UI,10'
    $AuthenticationComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $AuthenticationComboBox.Items.AddRange(@("Windows", "UserPassword"))
    $AuthenticationComboBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
    $AuthenticationComboBox.Add_DrawItem( { Show-ComboBox -combobox $AuthenticationComboBox } )

    $VersionTableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $VersionTableLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $VersionTableLayoutPanel.Height = 15
    
    $VersionLabel = New-Object system.Windows.Forms.Label
    $VersionLabel.text = "Version: $(Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\VERSION") -First 1)"
    $VersionLabel.AutoSize = $true
    $VersionLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Right` -bor [System.Windows.Forms.AnchorStyles]::Bottom
    $VersionLabel.Font = 'Segoe UI,8'
    $VersionLabel.ForeColor = "#b4b4b4"

    $ToolTips = New-Object system.Windows.Forms.ToolTip
    $ToolTips.SetToolTip($RTCPathComboBox, "NAV Version and the path in which the module can find the finsql.exe")
    $ToolTips.SetToolTip($RTCPathLabel, "NAV Version and the path in which the module can find the finsql.exe")
    $ToolTips.SetToolTip($SQLServerNameTextBox, "SQL server hostname\instance on which the NAV database can be found")
    $ToolTips.SetToolTip($SQLServerNameLabel, "SQL server hostname\instance on which the NAV database can be found")
    $ToolTips.SetToolTip($DatabaseNameTextBox, "Name of the NAV database")
    $ToolTips.SetToolTip($DatabaseNameLabel, "Name of the NAV database")
    $ToolTips.SetToolTip($TempFolderTextBox, "Temporary folder needed for module functions")
    $ToolTips.SetToolTip($TempFolderLabel, "Temporary folder needed for module functions")
    $ToolTips.SetToolTip($GitPathTextBox, "Git repository workspace folder in which the objects will be placed")
    $ToolTips.SetToolTip($GitPathLabel, "Git repository workspace folder in which the objects will be placed")
    $ToolTips.SetToolTip($AuthenticationComboBox, "Authentication type for the NAV database. User/Password will be prompted at runtime")
    $ToolTips.SetToolTip($AuthenticationLabel, "Authentication type for the NAV database. User/Password will be prompted at runtime")
    $ToolTips.SetToolTip($FobExportCheckBox, "Indicates whether third-party ID area will be exported and imported as fob(s) - Use with caution")
    $ToolTips.SetToolTip($FobExportLabel, "Indicates whether third-party ID area will be exported and imported as fob(s) - Use with caution")

    $ToolTips.SetToolTip($currentConfigComboBox, "Choose the current configuration from all existing configurations")
    $ToolTips.SetToolTip($NewButton, "Create a new configuration")
    $ToolTips.SetToolTip($EditButton, "Edit the current configuration")
    $ToolTips.SetToolTip($DeleteButton, "Delete the current configuration")
    $ToolTips.SetToolTip($ImportButton, "Import objects from Git repository into the NAV database")
    $ToolTips.SetToolTip($ExportButton, "Export objects from NAV database into the Git repository")
    $ToolTips.SetToolTip($SelectExportButton, "Filter the objects you want to export into the Git repository")
    $ToolTips.SetToolTip($FobForDeliveryButton, "Export the differences between your current Git repository and the database")

    $NavToGit_KeyDown = [System.Windows.Forms.KeyEventHandler] {
        if ($_.Alt -eq $true -and $_.KeyCode -eq 'Space') {
            if ($Global:dark -eq $false) { 
                Set-DarkMode
                $_.SuppressKeyPress = $true
                $Global:dark = $true
            }
            else {
                Set-StandardMode
                $_.SuppressKeyPress = $true
                $Global:dark = $false
            }
        }
    }

    $currentSettingsItems = @($RTCPathComboBox, $SQLServerNameTextBox, $DatabaseNameTextBox, $TempFolderTextBox, $TempFolderSelectionButton, $GitPathTextBox, $GitFolderSelectionButton, $AuthenticationComboBox, $FobExportCheckBox, $CompileCheckBox, $currentConfigComboBox, $ImportButton, $ExportButton, $SelectExportButton, $FobForDeliveryButton)
    $NavToGit.add_KeyDown($NavToGit_KeyDown)
    $CurrentConfigurationGroupBox.controls.AddRange($currentSettingsItems)
    $CurrentConfigurationGroupBox.controls.AddRange(@($currentConfigComboBox, $RTCPathLabel, $SQLServerNameLabel, $DatabaseNameLabel, $TempfolderLabel, $GitPathLabel, $AuthenticationLabel, $FobExportLabel, $CompileLabel, $EditButton, $DeleteButton, $newButton))
    $NavToGit.controls.AddRange(@($ImportButton, $ExportButton, $SelectExportButton, $FobForDeliveryButton, $CurrentConfigurationGroupBox))
    
    $VersionTableLayoutPanel.Controls.AddRange(@($VersionLabel))
    $NavToGit.controls.AddRange(@($VersionTableLayoutPanel))

    LoadConfig -config $config -currentConfigComboBox $currentConfigComboBox

    Set-ActiveItem -config $config -indexName $config.active -NavToGit $NavToGit
    Set-EditingMode -components $currentSettingsItems



    if ($dark) {
        Set-DarkMode
    }

    $NavToGit.Add_Shown( {
        if (($null -eq (Get-ObjectMembers $config).length)) {
            Invoke-ButtonNewClick -config $config -NavToGit $NavToGit -combobox $currentConfigComboBox -editingComponents $currentSettingsItems
            [System.Windows.Forms.MessageBox]::Show("No configuration found. Please set up.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } )

    $NavToGit.Add_Closing( {
        $guiconfig.MainWindowPosition.x = $NavToGit.DesktopLocation.X
        $guiconfig.MainWindowPosition.y = $NavToGit.DesktopLocation.Y
        $guiconfig.DarkMode = $Global:dark
        $guiconfig | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\gui.config.json")
    } )

    $NavToGit.ShowDialog()    
}

function Show-ComboBox {
    Param(
        $combobox
    )
    $_.DrawBackground()
    $_.DrawFocusRectangle()

    $index = $_.Index
    if ($index -lt 0) {
        return
    }
    $brush = [System.Drawing.Brushes]::Black
    if ($Global:dark) {
        $brush = [System.Drawing.Brushes]::White
    }
    $_.Graphics.DrawString($combobox.Items[$index].ToString(), $_.Font, $brush,
        (New-Object System.Drawing.PointF($_.Bounds.X, $_.Bounds.Y)), [System.Drawing.StringFormat]::GenericDefault)
}

function Invoke-TempFolderSelectionClick {

    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog  
    $FolderBrowser.ShowNewFolderButton = $true
    $FolderBrowser.ShowDialog()
              
    if ($FolderBrowser.SelectedPath -ne "") {
        $TempFolderTextBox.Text = $FolderBrowser.SelectedPath
    }
    $FolderBrowser.Dispose()
}

function Invoke-GitFolderSelectionClick {

    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.ShowNewFolderButton = $false
    $FolderBrowser.Description = "Please select the path where the objects should be placed after exporting"
    $FolderBrowser.ShowDialog()

    if ($FolderBrowser.SelectedPath -ne "") {
        $GitPathTextBox.Text = $FolderBrowser.SelectedPath
    }
    $FolderBrowser.Dispose()
}

function LoadConfig {
    Param(
        $config,
        $currentConfigComboBox
    )

    Write-Host "Reading config and fetching local NAV versions..."

    $ShowAvailableNAVVersions = Join-Path -Path (Split-Path (Split-Path -Parent ($PSScriptRoot)) -Parent) -ChildPath "public\Show-AvailableNAVVersions.ps1"
    . $ShowAvailableNAVVersions

    Get-ObjectMembers $config | ForEach-Object {
        if (-not ($_.Key -like "active")) {
            $currentConfigComboBox.Items.Add($_.Key) > $null
        }
    }

    $AllVersionsSorted = Show-AvailableNAVVersions
    $AllVersionsSorted.Keys | ForEach-Object {
        $RTCPathComboBox.Items.Add("$_ [$(Split-Path $AllVersionsSorted.Get_Item($_))]") > $null
    }

    try {
        [string]$CurrentVersion = Get-ChildItem (Join-Path -Path $config.$($config.active).RTCpath -ChildPath "finsql.exe") -ErrorAction SilentlyContinue | ForEach-Object { $_.VersionInfo.FileVersion } | ForEach-Object { $_.SubString(0, $_.LastIndexOf(".")) }
        [string]$currentRTCPath = [string]$CurrentVersion + " [" + $config.$($config.active).RTCPath.Trim("\") + "]"
        $RTCPathComboBox.SelectedIndex = $RTCPathComboBox.Items.IndexOf($currentRTCPath)
    }
    catch {
        $RTCPathComboBox.Text = ""
    }  
    
    $currentConfigComboBox.SelectedIndex = $currentConfigComboBox.Items.IndexOf($config.active)    

    Write-Host "Done"
}

function Set-EditingMode {
    Param(
        $components
    )
    
    $components | ForEach-Object {
        if ($_.GetType() -eq [System.Windows.Forms.TextBox]) {
            $_.ReadOnly = -Not $global:editing
        }
        elseif (($_ -eq $currentConfigComboBox) -or ($_ -eq $ImportButton) -or ($_ -eq $ExportButton) -or ($_ -eq $SelectExportButton) -or ($_ -eq $FobForDeliveryButton)) {
            $_.Enabled = -not $global:editing
        }
        else {
            $_.Enabled = $global:editing
        }
    }
    $NavToGit.Refresh()
}

function Set-ActiveItem {
    Param(
        $config,
        $indexName,
        $NavToGit
    )
    Get-ObjectMembers $config | ForEach-Object {
        if ($_.Key -like $indexName) {
            try {
                [string]$CurrentVersion = Get-ChildItem (Join-Path -Path $config.$indexName.RTCpath -ChildPath "finsql.exe") -ErrorAction SilentlyContinue | ForEach-Object { $_.VersionInfo.FileVersion } | ForEach-Object { $_.SubString(0, $_.LastIndexOf(".")) }
                [string]$currentRTCPath = [string]$CurrentVersion + " [" + $config.$indexName.RTCPath.Trim("\") + "]"
                
                $RTCPathComboBox.SelectedIndex = $RTCPathComboBox.Items.IndexOf($currentRTCPath)
            }
            catch {
                $RTCPathComboBox.Text = ""
            }
           
            $SQLServerNameTextBox.Text = $_.Value.SQLServerName
            $DatabaseNameTextBox.Text = $_.Value.DatabaseName
            $TempFolderTextBox.Text = $_.Value.Tempfolder
            $GitPathTextBox.Text = $_.Value.GitPath
            $AuthenticationComboBox.Text = $_.Value.Authentication
            $FobExportCheckBox.Checked = $_.Value.EnableThirdPartyFobExport
            $currentConfigComboBox.SelectedIndex = $currentConfigComboBox.Items.IndexOf($indexName)
            $CompileCheckBox.Checked = $_.Value.CompileObjects
        }
    }
    $config.active = $indexName
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

function Invoke-ButtonEditClick {
    Param(
        $config,
        $NavToGit
    )
    if ($editing) {
        if (-not [bool](Test-Config)){
            [System.Windows.Forms.MessageBox]::Show("Current Configuration is not complete.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        if (-not (Test-Path $TempFolderTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Temp Folder does not exist.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        if  (-not (Test-Path $GitPathTextBox.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Git Folder does not exist.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        
        $EditButton.Text = "&Edit"
        $DeleteButton.Text = "&Delete"
        Save-EditToConfig -config $config
    }elseif($Global:newMode){
        if (-not [bool](Test-Config)){
            [System.Windows.Forms.MessageBox]::Show("Current Configuration is not complete.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        Get-ObjectMembers $config | ForEach-Object {
            if ($currentConfigComboBox.Text -eq $_.key) {
                [System.Windows.Forms.MessageBox]::Show("A configuration with this name already exists.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
                $configNameExists= $true
            }
        }
        if ($configNameExists) {
            return
        }
        $rtcregex = [Regex]::new("\[(.*?)\]")
        $RTCPath = $rtcregex.Match($RTCPathComboBox.SelectedItem).Groups[1].Value
        $jsonBase = [PSCustomObject]@{ 
            "RTCPath"                   = $RTCPath;
            "DatabaseName"              = $DatabaseNameTextBox.Text;
            "Tempfolder"                = $TempFolderTextBox.Text;
            "GitPath"                   = $GitPathTextBox.Text;
            "SQLServerName"             = $SQLServerNameTextBox.Text;
            "Authentication"            = $AuthenticationComboBox.SelectedItem.ToString();
            "EnableThirdPartyFobExport" = $FobExportCheckBox.Checked;
            "CompileObjects"            = $CompileCheckBox.Checked;
        }
        Add-Member -InputObject $config -MemberType NoteProperty -Name $currentConfigComboBox.Text -Value $jsonBase
        Save-ConfigToDisk -config $config
        Set-ActiveItem -config $config -indexName $currentConfigComboBox.Text -NavToGit $NavToGit
        $currentConfigComboBox.SelectedIndex = $currentConfigComboBox.Items.Add($currentConfigComboBox.Text)
        $currentSettingsItems | ForEach-Object {
            if ($_.GetType() -eq [System.Windows.Forms.TextBox]) {
                $_.ReadOnly = $true
            }
            elseif ($_ -eq $currentConfigComboBox) {
                $_.Enabled = $true
                $_.DropDownStyle = [System.Windows.Forms.ComboboxStyle]::DropDownList
            }
            else {
                $_.Enabled = $global:editing
            }
        }
        $EditButton.Text = "&Edit"
        $DeleteButton.Text = "&Delete"
        $Global:newMode = $false
        $ImportButton.Enabled = $true
        $ExportButton.Enabled = $true
        $SelectExportButton.Enabled = $true
        $FobForDeliveryButton.Enabled = $true
        Set-EditingMode -components $currentSettingsItems
        return
    }
    else {
        $EditButton.Text = "&Save"
        $DeleteButton.Text = "&Cancel"
    }
    $global:editing = -Not $global:editing
    Set-EditingMode -components $currentSettingsItems
}
function Invoke-ButtonNewClick {
    Param(
        $config,
        $NavToGit,
        [System.Windows.Forms.ComboBox]$combobox,
        $editingComponents
    )
    if(-Not $Global:newMode){
        $combobox.DropDownStyle = [System.Windows.Forms.ComboboxStyle]::DropDown
        $combobox.Text = ""
        $editingComponents | ForEach-Object {
            $_.Enabled = $true
            if($_.GetType() -eq [System.Windows.Forms.TextBox]){
                $_.ReadOnly = $false
                $_.Text = ""
            }
            $TempFolderTextBox.Text = $env:TEMP
        }
        $AuthenticationComboBox.SelectedIndex = $AuthenticationComboBox.Items.IndexOf("Windows") 
        $FobExportCheckBox.Checked = $false
        $ImportButton.Enabled = $false
        $ExportButton.Enabled = $false
        $SelectExportButton.Enabled = $false
        $FobForDeliveryButton.Enabled = $false
        $EditButton.Text = "&Save"
        $DeleteButton.Text = "&Cancel"

        $Global:newMode = $true
    }
}


function Invoke-ConfigComboboxIndexChange {
    Param(
        $config,
        $NavToGit
    )
    Set-ActiveItem -config $config -indexName $currentConfigComboBox.SelectedItem.ToString()
    Save-ConfigToDisk -config $config
    $NavToGit.Refresh()
}

function Open-ExportMessageBox {
    $Result = [System.Windows.Forms.MessageBox]::Show("Are you sure to export objects with shown configuration?", "Export", 4, [System.Windows.Forms.MessageBoxIcon]::Question)
    If ($Result -eq "Yes") {
        [String]$argumentlist = '-noExit -command "$ExportFromNAVToGit = Join-Path -Path (Split-Path (Split-Path -Parent (""' + $PSScriptRoot + '""")) -Parent) -ChildPath "public\Export-FromNAVToGit.ps1";. $ExportFromNAVToGit; Export-FromNAVToGit"'
        Start-Process powershell.exe -ArgumentList $argumentlist
    }
}

function Open-GetFobMessageBox {
    $Result = [System.Windows.Forms.MessageBox]::Show("Are you sure to export the difference between database and your current Git Repository with shown configuration?", "Export", 4, [System.Windows.Forms.MessageBoxIcon]::Question)
    If ($Result -eq "Yes") {
        [String]$argumentlist = '-noExit -command "$GetFobForDelivery = Join-Path -Path (Split-Path (Split-Path -Parent (""' + $PSScriptRoot + '""")) -Parent) -ChildPath "public\Get-FobForDelivery.ps1";. $GetFobForDelivery; Get-FobForDelivery"'
        Start-Process powershell.exe -ArgumentList $argumentlist
    }
}

function Open-SelectiveExportMessageBox {
    $SelectiveExportMenu = Join-Path -Path (Split-Path (Split-Path -Parent ($PSScriptRoot)) -Parent) -ChildPath ".\private\gui\SelectiveExportMenu.ps1"
    . $SelectiveExportMenu
    
    $NAVVersion = Get-ChildItem (Join-Path -Path $config.$($config.active).RTCPath -ChildPath "finsql.exe") | ForEach-Object { $_.VersionInfo.FileVersion } | ForEach-Object { $_.SubString(0, $_.IndexOf(".")) }
    if ($NAVVersion -eq 6) {
        if ($dark) {
            Open-SelectiveExportMenu -dark -nav6
        }
        else {
            Open-SelectiveExportMenu -nav6
        }
    }
    else {    
        if ($dark) {
            Open-SelectiveExportMenu -dark
        }
        else {
            Open-SelectiveExportMenu
        }
    }
}

function Open-ImportMessageBox {
    $Result = [System.Windows.Forms.MessageBox]::Show("Are you sure to import objects with shown configuration?", "Import", 4, [System.Windows.Forms.MessageBoxIcon]::Question)
    If ($Result -eq "Yes") {
        [String]$argumentlist = '-noExit -command "$ImportFromGitToNAV = Join-Path -Path (Split-Path (Split-Path -Parent (""' + $PSScriptRoot + '""")) -Parent) -ChildPath "public\Import-FromGitToNAV.ps1";. $ImportFromGitToNAV; Import-FromGitToNAV' + $(if($Global:dark) {' -dark"'}else{'"'} )
        Start-Process powershell.exe -ArgumentList $argumentlist
    }
}

function Open-DeleteMessageBox {
    param(
        $config,
        $NavToGit
    )
    if (-not $Global:editing -and -not ($Global:newMode)) {
        if (((Get-ObjectMembers $config).length) -gt 2) {
            $Result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete configuration ""$($currentConfigComboBox.SelectedItem)""?", "Delete ""$($currentConfigComboBox.SelectedItem)""", 4, [System.Windows.Forms.MessageBoxIcon]::Warning)        
            if ($Result -eq "Yes") {
                if ($Global:editing) {
                    $Global:editing = $false
                    Set-EditingMode -components $currentSettingsItems
                }
                $DeletedConfig = $currentConfigComboBox.SelectedItem
                Remove-Config -config $config
                [System.Windows.Forms.MessageBox]::Show("Configuration ""$($DeletedConfig)"" has been deleted.", "", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Cannot delete configuration ""$($currentConfigComboBox.SelectedItem)"". You need to have at least one configuration.", "Error", 0, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    elseif($Global:newMode){
        $currentSettingsItems | ForEach-Object {
            if ($_.GetType() -eq [System.Windows.Forms.TextBox]) {
                $_.ReadOnly = $true
            }
            elseif ($_ -eq $currentConfigComboBox) {
                $_.Enabled = $true
                $_.DropDownStyle = [System.Windows.Forms.ComboboxStyle]::DropDownList
            }
            else {
                $_.Enabled = $global:editing
            }
        }
        $EditButton.Text = "&Edit"
        $DeleteButton.Text = "&Delete"
        $ImportButton.Enabled = $true
        $ExportButton.Enabled = $true
        $SelectExportButton.Enabled = $true
        $FobForDeliveryButton.Enabled = $true
        $Global:newMode = $false
        Set-ActiveItem -config $config -indexName $config.active -NavToGit $NavToGit
        $currentConfigComboBox.SelectedIndex = $currentConfigComboBox.Items.IndexOf($config.active)
        $NavToGit.Refresh()
    }
    else {
        $global:editing = -Not $global:editing
        $EditButton.Text = "&Edit"
        $DeleteButton.Text = "&Delete"
        Set-EditingMode -components $currentSettingsItems
        Set-ActiveItem -config $config -indexName $config.active
    }
}

function Remove-Config {
    param(
        $config
    )
    $config.PSObject.Properties.Remove($currentConfigComboBox.SelectedItem)
    $currentConfigComboBox.Items.Remove($currentConfigComboBox.SelectedItem)
    Get-ObjectMembers $config | ForEach-Object {
        if (-not ($_.Key -like "active")) {
            $config.active = $_.Key
            $currentConfigComboBox.SelectedIndex = $currentConfigComboBox.Items.IndexOf($config.active)
        }
    }
    Save-ConfigToDisk -config $config
}

function Save-ConfigToDisk {
    Param(
        $config
    )
    $config | ConvertTo-Json | Out-File -FilePath (Join-Path -Path $Env:APPDATA -ChildPath "\NavToGit\config.json")
}

function Save-EditToConfig {
    Param(
        $config
    )
    $rtcregex = [Regex]::new("\[(.*?)\]")
    $RTCPath = $rtcregex.Match($RTCPathComboBox.SelectedItem).Groups[1].Value
    
    $config.$($config.active).RTCPath = $RTCPath
    $config.$($config.active).SQLServerName = $SQLServerNameTextBox.Text
    $config.$($config.active).Databasename = $DatabaseNameTextBox.Text
    $config.$($config.active).Tempfolder = $TempFolderTextBox.Text
    $config.$($config.active).GitPath = $GitPathTextBox.Text
    $config.$($config.active).Authentication = $AuthenticationComboBox.Text
    $config.$($config.active).EnableThirdPartyFobExport = $FobExportCheckBox.Checked
    $config.$($config.active).CompileObjects = $CompileCheckBox.Checked

    Save-ConfigToDisk -config $config
}

function Set-DarkMode {
    $NavToGit.BackColor = "#383838"
    $CurrentConfigurationGroupBox.ForeColor = "#d4d4d4"
    $SQLServerNameTextBox.BackColor = "#383838"
    $SQLServerNameTextBox.ForeColor = "#d4d4d4"
    $DatabaseNameTextBox.BackColor = "#383838"
    $DatabaseNameTextBox.ForeColor = "#d4d4d4"
    $TempFolderTextBox.BackColor = "#383838"
    $TempFolderTextBox.ForeColor = "#d4d4d4"
    $GitPathTextBox.BackColor = "#383838"
    $GitPathTextBox.ForeColor = "#d4d4d4"
    $NewButton.BackColor = "#1e1e1e"
    $EditButton.BackColor = "#1e1e1e"
    $DeleteButton.BackColor = "#1e1e1e"
    $TempFolderSelectionButton.BackColor = "#1e1e1e"
    $GitFolderSelectionButton.BackColor = "#1e1e1e"
    $currentConfigComboBox.BackColor = "#383838"
    $currentConfigComboBox.ForeColor = "#d4d4d4"
    $RTCPathComboBox.BackColor = "#383838"
    $RTCPathComboBox.ForeColor = "#d4d4d4"
    $AuthenticationComboBox.BackColor = "#383838"
    $AuthenticationComboBox.ForeColor = "#d4d4d4"
}

function Set-StandardMode {
    $NavToGit.ResetBackColor()
    $CurrentConfigurationGroupBox.ResetForeColor()
    $SQLServerNameTextBox.ResetBackColor()
    $SQLServerNameTextBox.ResetForeColor()
    $DatabaseNameTextBox.ResetBackColor()
    $DatabaseNameTextBox.ResetForeColor()
    $TempFolderTextBox.ResetBackColor()
    $TempFolderTextBox.ResetForeColor()
    $GitPathTextBox.ResetBackColor()
    $GitPathTextBox.ResetForeColor()
    $NewButton.ResetBackColor()
    $EditButton.ResetBackColor()
    $DeleteButton.ResetBackColor()
    $TempFolderSelectionButton.ResetBackColor()
    $GitFolderSelectionButton.ResetBackColor()
    $currentConfigComboBox.ResetBackColor()
    $currentConfigComboBox.ResetForeColor()
    $RTCPathComboBox.ResetBackColor()
    $RTCPathComboBox.ResetForeColor()
    $AuthenticationComboBox.ResetBackColor()
    $AuthenticationComboBox.ResetForeColor()
}

function Test-Config{
    $isOkay = $true   
    $currentSettingsItems | ForEach-Object {
        if ($_.GetType() -eq [System.Windows.Forms.TextBox] -and [System.String]::IsNullOrEmpty($_.Text)) {
            $isOkay = $false
        }
    }
    if ($currentConfigComboBox.Text -eq "") {
        $isOkay = $false
    }
    return $isOkay
}