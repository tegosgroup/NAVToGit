function Open-SelectiveImportMenu {
    param(
        [switch]$dark,
        [switch]$nav6
    )

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $SelectiveImport = New-Object system.Windows.Forms.Form
    $SelectiveImport.ClientSize = '340,480'
    $SelectiveImport.text = "Selective Import"
    $SelectiveImport.MaximizeBox = $false
    $SelectiveImport.FormBorderStyle = 'Fixed3D'
    $SelectiveImport.TopMost = $false
    $SelectiveImport.StartPosition = 1

    $PleaseEnterLabel = New-Object system.Windows.Forms.Label
    $PleaseEnterLabel.text = "Please enter your desired filters:"
    $PleaseEnterLabel.AutoSize = $true
    $PleaseEnterLabel.width = 25
    $PleaseEnterLabel.height = 10
    $PleaseEnterLabel.location = New-Object System.Drawing.Point(20, 15)
    $PleaseEnterLabel.Font = 'Segoe UI,10,style=Bold'

    $CodeunitLabel = New-Object system.Windows.Forms.Label
    $CodeunitLabel.text = "Codeunit"
    $CodeunitLabel.AutoSize = $true
    $CodeunitLabel.width = 25
    $CodeunitLabel.height = 10
    $CodeunitLabel.location = New-Object System.Drawing.Point(20, 47)
    $CodeunitLabel.Font = 'Segoe UI,10'

    $CodeunitTextBox = New-Object system.Windows.Forms.TextBox
    $CodeunitTextBox.multiline = $false
    $CodeunitTextBox.width = 231
    $CodeunitTextBox.height = 20
    $CodeunitTextBox.location = New-Object System.Drawing.Point(96, 43)
    $CodeunitTextBox.Font = 'Segoe UI,10'
    $CodeunitTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $MenuSuiteLabel = New-Object system.Windows.Forms.Label
    $MenuSuiteLabel.text = "Menusuite"
    $MenuSuiteLabel.AutoSize = $true
    $MenuSuiteLabel.width = 25
    $MenuSuiteLabel.height = 10
    $MenuSuiteLabel.location = New-Object System.Drawing.Point(20, 84)
    $MenuSuiteLabel.Font = 'Segoe UI,10'

    $MenuSuiteTextBox = New-Object system.Windows.Forms.TextBox
    $MenuSuiteTextBox.multiline = $false
    $MenuSuiteTextBox.width = 231
    $MenuSuiteTextBox.height = 20
    $MenuSuiteTextBox.location = New-Object System.Drawing.Point(96, 80)
    $MenuSuiteTextBox.Font = 'Segoe UI,10'
    $MenuSuiteTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $PageLabel = New-Object system.Windows.Forms.Label
    $PageLabel.text = "Page"
    $PageLabel.AutoSize = $true
    $PageLabel.width = 25
    $PageLabel.height = 10
    $PageLabel.location = New-Object System.Drawing.Point(20, 121)
    $PageLabel.Font = 'Segoe UI,10'

    $PageTextBox = New-Object system.Windows.Forms.TextBox
    $PageTextBox.multiline = $false
    $PageTextBox.width = 231
    $PageTextBox.height = 20
    $PageTextBox.location = New-Object System.Drawing.Point(96, 117)
    $PageTextBox.Font = 'Segoe UI,10'
    $PageTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $QueryLabel = New-Object system.Windows.Forms.Label
    $QueryLabel.text = "Query"
    $QueryLabel.AutoSize = $true
    $QueryLabel.width = 25
    $QueryLabel.height = 10
    $QueryLabel.location = New-Object System.Drawing.Point(20, 157)
    $QueryLabel.Font = 'Segoe UI,10'

    $QueryTextBox = New-Object system.Windows.Forms.TextBox
    $QueryTextBox.multiline = $false
    $QueryTextBox.width = 231
    $QueryTextBox.height = 20
    $QueryTextBox.location = New-Object System.Drawing.Point(96, 153)
    $QueryTextBox.Font = 'Segoe UI,10'
    $QueryTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $DataportLabel = New-Object system.Windows.Forms.Label
    $DataportLabel.text = "Dataport"
    $DataportLabel.AutoSize = $true
    $DataportLabel.width = 25
    $DataportLabel.height = 10
    $DataportLabel.location = New-Object System.Drawing.Point(20, 157)
    $DataportLabel.Font = 'Segoe UI,10'
    $DataportLabel.Visible = $false  

    $DataportTextBox = New-Object system.Windows.Forms.TextBox
    $DataportTextBox.multiline = $false
    $DataportTextBox.width = 231
    $DataportTextBox.height = 20
    $DataportTextBox.location = New-Object System.Drawing.Point(96, 153)
    $DataportTextBox.Font = 'Segoe UI,10'
    $DataportTextBox.Visible = $false
    $DataportTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $ReportLabel = New-Object system.Windows.Forms.Label
    $ReportLabel.text = "Report"
    $ReportLabel.AutoSize = $true
    $ReportLabel.width = 25
    $ReportLabel.height = 10
    $ReportLabel.location = New-Object System.Drawing.Point(20, 194)
    $ReportLabel.Font = 'Segoe UI,10'

    $ReportTextBox = New-Object system.Windows.Forms.TextBox
    $ReportTextBox.multiline = $false
    $ReportTextBox.width = 231
    $ReportTextBox.height = 20
    $ReportTextBox.location = New-Object System.Drawing.Point(96, 190)
    $ReportTextBox.Font = 'Segoe UI,10'
    $ReportTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $TableLabel = New-Object system.Windows.Forms.Label
    $TableLabel.text = "Table"
    $TableLabel.AutoSize = $true
    $TableLabel.width = 25
    $TableLabel.height = 10
    $TableLabel.location = New-Object System.Drawing.Point(20, 231)
    $TableLabel.Font = 'Segoe UI,10'

    $TableTextBox = New-Object system.Windows.Forms.TextBox
    $TableTextBox.multiline = $false
    $TableTextBox.width = 231
    $TableTextBox.height = 20
    $TableTextBox.location = New-Object System.Drawing.Point(96, 227)
    $TableTextBox.Font = 'Segoe UI,10'
    $TableTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $XMLPortLabel = New-Object system.Windows.Forms.Label
    $XMLPortLabel.text = "XMLPort"
    $XMLPortLabel.AutoSize = $true
    $XMLPortLabel.width = 25
    $XMLPortLabel.height = 10
    $XMLPortLabel.location = New-Object System.Drawing.Point(20, 268)
    $XMLPortLabel.Font = 'Segoe UI,10'

    $XMLPortTextBox = New-Object system.Windows.Forms.TextBox
    $XMLPortTextBox.multiline = $false
    $XMLPortTextBox.width = 231
    $XMLPortTextBox.height = 20
    $XMLPortTextBox.location = New-Object System.Drawing.Point(96, 264)
    $XMLPortTextBox.Font = 'Segoe UI,10'
    $XMLPortTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })

    $FormLabel = New-Object system.Windows.Forms.Label
    $FormLabel.text = "Form"
    $FormLabel.AutoSize = $true
    $FormLabel.width = 25
    $FormLabel.height = 10
    $FormLabel.location = New-Object System.Drawing.Point(20, 305)
    $FormLabel.Font = 'Segoe UI,10'
    $FormLabel.Visible = $false

    $FormTextBox = New-Object system.Windows.Forms.TextBox
    $FormTextBox.multiline = $false
    $FormTextBox.width = 231
    $FormTextBox.height = 20
    $FormTextBox.location = New-Object System.Drawing.Point(96, 301)
    $FormTextBox.Font = 'Segoe UI,10'
    $FormTextBox.Visible = $false
    $FormTextBox.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") {
            Invoke-OKButtonClick
        }
    })


    $NoteGroupBox = New-Object system.Windows.Forms.Groupbox
    $NoteGroupBox.width = 310
    $NoteGroupBox.height = 100
    $NoteGroupBox.text = "Note"
    $NoteGroupBox.location = New-Object System.Drawing.Point(16, 366)

    $NoteLabel = New-Object system.Windows.Forms.Label
    $NoteLabel.Text = "Please enter the filter just as you would in Dynamics NAV. Different to selective Export only filtering on id is possible. Empty filters will be ignored and no object of this type will be imported." + [System.Environment]::NewLine + "Example: id=1337..1360"
    $NoteLabel.AutoSize = $false
    $NoteLabel.width = 288
    $NoteLabel.height = 80
    $NoteLabel.location = New-Object System.Drawing.Point(8, 15)
    $NoteLabel.Font = 'Segoe UI,9'

    $OKButton = New-Object system.Windows.Forms.Button
    $OKButton.text = "&OK"
    $OKButton.width = 60
    $OKButton.height = 30
    $OKButton.location = New-Object System.Drawing.Point(20, 315)
    $OKButton.Font = 'Segoe UI,10'
    $OKButton.Add_Click( { Invoke-OKButtonClick -nav6:$nav6})

    $CancelButton = New-Object system.Windows.Forms.Button
    $CancelButton.text = "&Cancel"
    $CancelButton.width = 60
    $CancelButton.height = 30
    $CancelButton.location = New-Object System.Drawing.Point(96, 315)
    $CancelButton.Font = 'Segoe UI,10'
    $CancelButton.Add_Click( { Invoke-CancelButtonClick })

    if ($nav6) {
        $QueryLabel.Visible = $false
        $QueryTextBox.Visible = $false
        $DataportLabel.Visible = $true
        $DataportTextBox.Visible = $true
        $FormLabel.Visible = $true
        $FormTextBox.Visible = $true
        $SelectiveImport.ClientSize = '340,510'
        $OKButton.location = New-Object System.Drawing.Point(20, 352)
        $CancelButton.location = New-Object System.Drawing.Point(96, 352)
        $NoteGroupBox.location = New-Object System.Drawing.Point(16, 403)
    }

    $SelectiveImport.controls.AddRange(@($CodeunitLabel, $CodeunitTextBox, $MenuSuiteLabel, $MenuSuiteTextBox, $PageLabel, $PageTextBox, $QueryLabel, $QueryTextBox, $ReportLabel, $ReportTextBox, $TableLabel, $TableTextBox, $XMLPortLabel, $XMLPortTextBox, $PleaseEnterLabel, $NoteGroupBox, $OKButton, $CancelButton, $DataportLabel, $DataportTextBox, $FormLabel, $FormTextBox))
    $NoteGroupBox.controls.AddRange(@($NoteLabel))

    if ($dark) {
        Set-DarkMode
    }
    
    $SelectiveImport.ShowDialog()
}

function Invoke-OKButtonClick {
    param (
        $nav6
    )
    [string]$CustomFilter = """codeunit=" + $CodeunitTextBox.Text + ";menusuite=" + $MenuSuiteTextBox.Text + ";page=" + $PageTextBox.Text + ";report=" + $ReportTextBox.Text + ";table=" + $TableTextBox.Text + ";xmlport=" + $XMLPortTextBox.Text
    if ($nav6){
        $CustomFilter = $CustomFilter + ";dataport=" + $DataportTextBox.Text + ";form=" + $FormTextBox.Text
    }
    else{
        $CustomFilter = $CustomFilter + ";query=" + $QueryTextBox.Text        
    }
    $CustomFilter = $CustomFilter + """"

    $CustomFilter

    [String]$argumentlist = '-noExit -command "$ImportFromGitToNAV = Join-Path -Path (Split-Path (Split-Path -Parent (""' + $PSScriptRoot + '""")) -Parent) -ChildPath "public\Import-FromGitToNAV.ps1";. $ImportFromGitToNAV; Import-FromGitToNAV -customfilter ""' + $CustomFilter + '"""'

    $argumentlist
    Start-Process powershell.exe -ArgumentList $argumentlist
    $SelectiveImport.Close()
}
function Invoke-CancelButtonClick {
    $SelectiveImport.Close()
}

function Set-DarkMode {
    $SelectiveImport.BackColor = "#383838"
    $PleaseEnterLabel.ForeColor = "#d4d4d4"
    $CodeunitLabel.ForeColor = "#d4d4d4"
    $CodeunitTextBox.BackColor = "#383838"
    $CodeunitTextBox.ForeColor = "#d4d4d4"
    $MenusuiteLabel.ForeColor = "#d4d4d4"
    $MenusuiteTextBox.BackColor = "#383838"
    $MenusuiteTextBox.ForeColor = "#d4d4d4"
    $PageLabel.ForeColor = "#d4d4d4"
    $PageTextBox.BackColor = "#383838"
    $PageTextBox.ForeColor = "#d4d4d4"
    $QueryLabel.ForeColor = "#d4d4d4"
    $QueryTextBox.BackColor = "#383838"
    $QueryTextBox.ForeColor = "#d4d4d4"
    $ReportLabel.ForeColor = "#d4d4d4"
    $ReportTextBox.BackColor = "#383838"
    $ReportTextBox.ForeColor = "#d4d4d4"
    $TableLabel.ForeColor = "#d4d4d4"
    $TableTextBox.BackColor = "#383838"
    $TableTextBox.ForeColor = "#d4d4d4"
    $XMLPortLabel.ForeColor = "#d4d4d4"
    $XMLPortTextBox.BackColor = "#383838"
    $XMLPortTextBox.ForeColor = "#d4d4d4"
    $OKButton.ForeColor = "#d4d4d4"
    $CancelButton.ForeColor = "#d4d4d4"
    $NoteGroupBox.ForeColor = "#d4d4d4"
    $NoteLabel.ForeColor = "#d4d4d4"
    $DataportLabel.ForeColor = "#d4d4d4"
    $DataportTextBox.ForeColor = "#d4d4d4"
    $DataportTextBox.BackColor = "#383838"
    $FormLabel.ForeColor = "#d4d4d4"
    $FormTextBox.ForeColor = "#d4d4d4"
    $FormTextBox.BackColor = "#383838"
    $SelectiveImport.Refresh()
}