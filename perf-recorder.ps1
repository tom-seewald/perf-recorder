###############################
# Performance Recorder Script #
###############################

# Check that this script is being run with elevated credentials, otherwise abort

$elevatedcheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

If ( "$elevatedcheck" -ne "True" ) {
	
	Write-Warning "ERROR: Administrator rights are required for this script to work properly!"
	Write-Warning "Aborting script!"
	exit
}

# Verify that wpr.exe exists, otherwise abort

$wprcheck = Test-Path "$env:SystemRoot\System32\wpr.exe"

If ( $wprcheck -ne "True" ) {

	Write-Warning "ERROR: wpr.exe not found in System32 folder!"
	Write-Warning "Aborting script!"
	exit
}

# Ensure that wpr.exe is not already running

wpr.exe -cancel 2> $null

# Prompt user to choose what profiles to use

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form 
$form.Text = "WPR Profile Selection"
$form.Size = New-Object System.Drawing.Size(300,280) 
$form.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(95,205)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(190,205)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20) 
$label.Size = New-Object System.Drawing.Size(280,20) 
$label.Text = "Select one or more profiles from the list:"
$form.Controls.Add($label) 

$listBox = New-Object System.Windows.Forms.Listbox 
$listBox.Location = New-Object System.Drawing.Point(10,40) 
$listBox.Size = New-Object System.Drawing.Size(260,20) 

$listBox.SelectionMode = "MultiExtended"

[void] $listBox.Items.Add("General Profile")
[void] $listBox.Items.Add("CPU")
[void] $listBox.Items.Add("Disk I/O")
[void] $listBox.Items.Add("File I/O")
[void] $listBox.Items.Add("GPU")
[void] $listBox.Items.Add("Handles")
[void] $listBox.Items.Add("Pool")
[void] $listBox.Items.Add("Minifilter I/O")
[void] $listBox.Items.Add("Network")
[void] $listBox.Items.Add("Registry")
[void] $listBox.Items.Add("Sound")
[void] $listBox.Items.Add("Video")

$listBox.Height = 170
$form.Controls.Add($listBox) 
$form.Topmost = $True

$result = $form.ShowDialog()

$selectedprofiles = $listBox.SelectedItems

# If the user pressed cancel or closed the window, abort the script

If ( $result -ne [System.Windows.Forms.DialogResult]::OK ) {
		
	Write-Warning "No items selected!"
	Write-Warning "Aborting script"
	exit
}

# If the user selected 0 items and pressed OK, abort the script

If ( !$selectedprofiles ) {

	Write-Warning "No items selected!"
	Write-Warning "Aborting script"
	exit
}

# If the user selected 1 or more items and pressed OK, print their selection and continue

If ( $result -eq [System.Windows.Forms.DialogResult]::OK ) {
	
	Write-Host "`n"
	Write-Host "Selected Profiles:"
	Write-Host "`n"
	$selectedprofiles
	Write-Host "`n"
}

# Create wpr.exe arguments from the profiles selected

If ( $selectedprofiles -contains "General Profile" ) {

	$wprarguments = $wprarguments + "-start GeneralProfile"
}

If ( $selectedprofiles -contains "CPU" ) {

	$wprarguments = $wprarguments + "-start CPU"
}

If ( $selectedprofiles -contains "Disk I/O" ) {

	$wprarguments = $wprarguments + "-start DiskIO"
}	

If ( $selectedprofiles -contains "File I/O" ) {

	$wprarguments = $wprarguments + "-start FileIO"
}

If ( $selectedprofiles -contains "-start GPU" ) {

	$wprarguments = $wprarguments + "-start GPU"
}

If ( $selectedprofiles -contains "Handles" ) {

	$wprarguments = $wprarguments + "-start Handle"
}

If ( $selectedprofiles -contains "Registry" ) {

	$wprarguments = $wprarguments + "-start Registry"
}

If ( $selectedprofiles -contains "Sound" ) {

	$wprarguments = $wprarguments + "-start Audio"
}

If ( $selectedprofiles -contains "Video" ) {

	$wprarguments = $wprarguments + "-start Video"
}

# Add a space between arguments

$wprarguments = $wprarguments -replace "-", " -"

# Remove the first leading space

$wprarguments = $wprarguments -replace "^ -", "-"

# Prompt user for amount of time (in seconds) the collection should run

$form = New-Object System.Windows.Forms.Form 
$form.Text = "Length of time"
$form.Size = New-Object System.Drawing.Size(300,200) 
$form.StartPosition = "CenterScreen"

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $OKButton
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20) 
$label.Size = New-Object System.Drawing.Size(280,20) 
$label.Text = "Time, in seconds, that the trace will run (1-300)"
$form.Controls.Add($label) 

$textBox = New-Object System.Windows.Forms.TextBox 
$textBox.Location = New-Object System.Drawing.Point(10,40) 
$textBox.Size = New-Object System.Drawing.Size(260,20) 
$form.Controls.Add($textBox) 

$form.Topmost = $True

$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

# Ensure the input is a decimal, if it is not a decimal this will set $timelimitseconds to $null

$timelimitseconds = $textBox.Text -as [decimal]

# If the user pressed cancel or closed the window, abort the script

If ( $result -ne [System.Windows.Forms.DialogResult]::OK ) {
		
	Write-Warning "Input box was closed or canceled!"
	Write-Warning "Aborting script"
	exit
}

# If the user entered nothing or an invalid string and pressed OK, abort the script

If ( !$timelimitseconds ) {

	Write-Warning "Nothing was entered!"
	Write-Warning "Aborting script"
	exit
}

# If the entered amount is too high, abort the script

If ( $timelimitseconds -gt 300 -or $timelimitseconds -lt 1 ) {
	
	Write-Warning "Invalid time limit"
	Write-Warning "Aborting script"
	exit
}
  
# Prompt user to choose where to place the output

Write-Host "Please select the output directory for the trace"

$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
[void]$FolderBrowser.ShowDialog()

$date = Get-Date -format M-d-yyyy

$folderpath = $FolderBrowser.SelectedPath
  
$outputpath = $FolderBrowser.SelectedPath + "\trace-($date).etl"

$generated_symbols = "$outputpath" + ".etl.NGENPDB"

Write-Host "`n"
Write-Host "Selected output folder: $folderpath"
Write-Host "`n"

# Abort if path is empty

If ( $folderpath -eq "" ) {

	Write-Warning "Empty file path"
	Write-Warning "Aborting script..."
	exit
}

# Abort if path selected is invalid

If ( (Test-Path "$folderpath") -eq $False ) {

	Write-Warning "Invalid path!"
	Write-Warning "Aborting script..."
	exit
}

# If a name collision will occur, remove the old .etl file

If ( Test-Path "$outputpath" ) {

	Remove-Item "$outputpath"
}

# Start wpr.exe with the selected profiles

Write-Host "Running wpr.exe for $timelimitseconds seconds..."
Write-Host "`n"

Start-Process -FilePath "$env:SystemRoot\System32\wpr.exe" -ArgumentList $wprarguments -NoNewWindow

# Wait for the specified amount of time before stopping collection

$startDate = Get-Date

While ( $startDate.AddSeconds($timelimitseconds) -gt (Get-Date) ) {

	Start-Sleep -Seconds .5	
}

# Once timelimit has been reached, stop collection and generate the .etl file

If ( $startDate.AddSeconds($timelimitseconds) -le (Get-Date) ) {

	Write-Host "Generating trace file..."

	wpr.exe -stop "$outputpath"
}

If ( Test-Path "$generated_symbols" ) { 

	Remove-Item -Recurse "$generated_symbols"
}

Write-Host "`n"
Write-Host "Performance Trace Complete!"
Write-Host "`n"
Write-Host "Output: $outputpath"
Write-Host "`n"
Read-Host -Prompt "Press Enter to Exit"