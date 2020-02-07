$Global:ObjectListGUI > $null
$Global:DataGridView > $null
$Global:Git > $null
$Global:Temp > $null
$Global:ResultList = New-Object Collections.Generic.List[String]
function Open-ObjectList {
    Param (
        $git,
        $temp,
        $CompareToolPath,
        $CompareToolParam,
        [switch]$dark
    )
    $Global:Git = $git
    $Global:Temp = $temp
    $Global:CompareToolPath = $CompareToolPath
    $Global:CompareToolParam = $CompareToolParam
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $Global:ObjectListGUI = New-Object system.Windows.Forms.Form
    $Global:ObjectListGUI.SuspendLayout()
    $Global:ObjectListGUI.ClientSize = '660,480'
    $Global:ObjectListGUI.Text = "Choose changes to import"
    $Global:ObjectListGUI.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide

    $Global:dataGridView = New-Object System.Windows.Forms.DataGridView
    [System.ComponentModel.ISupportInitialize]$Global:dataGridView.BeginInit()
    $Global:dataGridView.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $Global:dataGridView.AllowUserToResizeRows = $false
    $Global:dataGridView.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $Global:dataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $Global:dataGridView.GridColor = [System.Drawing.SystemColors]::ControlDark
    $Global:dataGridView.Location = '12,12'
    $Global:dataGridView.Size = '640,431'
    $Global:dataGridView.TabIndex = 0
    $Global:dataGridView.ShowEditingIcon = $false
    $Global:dataGridView.RowTemplate.Resizable = [System.Windows.Forms.DataGridViewTriState]::True
    $Global:dataGridView.Name = "DataGridView"
    $Global:dataGridView.RowHeadersVisible = $false
    $Global:dataGridView.CellBorderStyle = [System.Windows.Forms.DataGridViewCellBorderStyle]::SingleHorizontal
    $Global:dataGridView.ColumnHeadersBorderStyle = [System.Windows.Forms.DataGridViewHeaderBorderStyle]::Sunken
    $Global:dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $Global:dataGridView.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize

    $Global:dataGridView.Add_MouseClick( {
            $rowIndex = $dataGridView.HitTest($_.X, $_.Y).RowIndex
            if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right -and $rowIndex -ge 0) {
                $Global:dataGridView.Rows | ForEach-Object {
                    $_.Selected = $false
                }
                $Global:dataGridView.Rows[$rowIndex].Selected = $true
                $menuItemCompare = New-Object System.Windows.Forms.MenuItem("Compare files")
                $menuItemCompare.Add_Click( {
                        $file = $dataGridView.SelectedRows[0].Cells[$dataGridView.ColumnCount - 1].Value
                        Show-ChangesInApplication -gitPath $Global:Git -databasePath $Global:Temp -CompareToolPath $Global:CompareToolPath -CompareToolParam $Global:CompareToolParam -filename $file
                    })

                $contextMenu = New-Object System.Windows.Forms.ContextMenu
                $contextMenu.MenuItems.Add($menuItemCompare)
                $contextMenu.Show($dataGridView, (New-Object System.Drawing.Point($_.X, $_.Y)))
            }
        })
    
    $DiffHintLabel = New-Object system.Windows.Forms.Label
    $DiffHintLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
    $DiffHintLabel.text = "Right click on object to compare object versions"
    $DiffHintLabel.ForeColor = '#A0A0A0'
    $DiffHintLabel.AutoSize = $true
    $DiffHintLabel.width = 60
    $DiffHintLabel.height = 10
    $DiffHintLabel.location = '12,450'
    $DiffHintLabel.Font = 'Segoe UI,10'

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnCancel.Name = "btnCancel"
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = '75,25'
    $btnCancel.Location = '575,447'
    $btnCancel.TabIndex = 1
    $btnCancel.Font = 'Segoe UI,10'
    $btnCancel.UseVisualStyleBackColor = $true
    $btnCancel.Add_Click( {
            $Global:ResultList.Clear()
            $Global:ObjectListGUI.Hide()
        })

    $btnImportSelected = New-Object System.Windows.Forms.Button
    $btnImportSelected.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnImportSelected.Location = '410,447'
    $btnImportSelected.Size = '160,25'
    $btnImportSelected.Font = 'Segoe UI,10'
    $btnImportSelected.Name = "btnImportSelected"
    $btnImportSelected.Text = "Import selected objects"
    $btnImportSelected.Add_Click( {
            $Global:ResultList.Clear()
            $Global:DataGridView.SelectedRows | ForEach-Object {
                $Global:ResultList.Add($_.Cells[$dataGridView.ColumnCount - 1].Value)
            }
            $Global:ObjectListGUI.Hide()
        })


    $Global:ObjectListGUI.Controls.Add($btnCancel)
    $Global:ObjectListGUI.Controls.Add($btnImportSelected)
    $Global:ObjectListGUI.Controls.Add($DiffHintLabel)
    $Global:ObjectListGUI.Controls.Add($Global:dataGridView)

    [System.ComponentModel.ISupportInitialize]$Global:dataGridView.EndInit()

    if ($dark) {
        Set-DarkModeForCompareList
    }

    $Global:ObjectListGUI.ResumeLayout()
}

function Initialize-GridViewWithPsObjects {
    Param(
        [System.Collections.Generic.List[PsCustomObject]]$dataList,
        [Array]$excludedProperties,
        [switch]$dark
    )
    if ($dark) {
        $Global:dataGridView.ColumnHeadersDefaultCellStyle.BackColor = '#383838'
        $Global:dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = '#d4d4d4'
        $Global:dataGridView.EnableHeadersVisualStyles = $false
    }

    $dataList[0].PSObject.Properties | ForEach-Object {
        if (-Not ($excludedProperties -match $_.Name)) {
            $column = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $column.HeaderText = $_.Name
            $column.Name = $_.Name
            $column.ReadOnly = $true
            $dataGridView.Columns.Add($column) > $null
        }
    }

    $dataList | ForEach-Object {
        $count = 0
        $row = $dataGridView.Rows[0].Clone()
        $_.PSObject.Properties | ForEach-Object {
            if (-Not ($excludedProperties -match $_.Name)) {
                $row.Cells[$count].Value = $_.Value
                $count = $count + 1
            }
        }
        $row.Resizable = [System.Windows.Forms.DataGridViewTriState]::False
        $row.DefaultCellStyle.ForeColor = ConvertTo-Color -int (Resolve-FileChangesForImport -gitPath $git -databasePath $temp -relativeFilePath $_.'Object File Name' )
        if ($dark) {
            $row.DefaultCellStyle.BackColor = '#383838'
        }
        $dataGridView.Rows.Add($row) > $null
    }
    $Global:dataGridView.AllowUserToAddRows = $false
    $Global:dataGridView.Columns[$Global:dataGridView.Columns.Count-1].Visible = $false
}

function Set-DarkModeForCompareList {
    Param(
    )
    $DiffHintLabel.BackColor = '#383838'
    $DiffHintLabel.ForeColor = '#d4d4d4'
    $btnCancel.BackColor = '#1e1e1e'
    $btnImportSelected.BackColor = '#1e1e1e'
    $btnCancel.ForeColor = '#d4d4d4'
    $btnImportSelected.ForeColor = '#d4d4d4'
    $Global:ObjectListGUI.BackColor = '#383838'
    $Global:DataGridView.BackgroundColor = '#383838'

}

function ConvertTo-Color {
    Param(
        [int]$int
    )
    if ($dark) {
        switch ($int) {
            -1 { return [System.Drawing.Color]::Red }
            0 { return [System.Drawing.Color]::DeepSkyBlue }
            1 { return [System.Drawing.Color]::LightGreen }
        }
    }
    else {
        switch ($int) {
            -1 { return [System.Drawing.Color]::Red }
            0 { return [System.Drawing.Color]::Blue }
            1 { return [System.Drawing.Color]::Green }
        }
    }
}

function Show-Dialog {
    $Global:ObjectListGUI.ShowDialog() > $null
    return $Global:ResultList
}