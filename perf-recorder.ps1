###############################################################################################
# Performance Recorder Script 																  #
# About: This is a simple wrapper around wpr.exe to facilitate end-users gathering ETW traces #
# Script Author: Spectrum																	  #
###############################################################################################

[CmdletBinding()]
Param
(
	[bool]
	$KeepPDB = $False
)

# Required for drawing menus
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$VersionString  = "Script Version: 7.28.18"
$TimeStamp	    = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$FolderName     = "$env:ComputerName-Trace-($TimeStamp)"
$ZipName        = $FolderName + ".zip"
$TempOutputPath = Join-Path -Path $env:Temp -ChildPath $FolderName
$TempETLPath    = Join-Path -Path $TempOutputPath -ChildPath "trace.etl"
$TranscriptPath = Join-Path -Path $TempOutputPath -ChildPath "log.txt"
$SymbolPath     = $TempETLPath + ".NGENPDB"
$WPR		    = "$env:SystemRoot\system32\wpr.exe"
$ElevatedTest   = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
$WPRTest        = Test-Path -Path $WPR

# Get Windows Build
$WindowsBuild = [System.Environment]::OSVersion.Version.Build

# Minimum Windows Build supported
$MinimumBuild = 10240

# Time limits for tracing
$LowerTimeLImitSeconds = 5
$UpperTimeLimitSeconds = 600
$ValidTimeRange        = $LowerTimeLimitSeconds..$UpperTimeLimitSeconds

# WPR profiles
$ValidProfiles =
@(
	"GeneralProfile",
	"CPU",
	"DiskIO",
	"FileIO",
	"Registry",
	"Network",
	"Heap",
	"Pool",
	"VirtualAllocation",
	"Audio",
	"Video",
	"Power",
	"InternetExplorer",
	"EdgeBrowser",
	"Minifilter",
	"GPU",
	"Handle",
	"XAMLActivity",
	"HTMLActivity",
	"DesktopComposition",
	"XAMLAppResponsiveness",
	"HTMLResponsiveness",
	"ReferenceSet",
	"ResidentSet",
	"XAMLHTMLAppMemoryAnalysis",
	"UTC",
	"DotNET",
	"WdfTraceLoggingProvider",
	"HeapSnapshot"
)

# Verify that this script is being run with elevated credentials, if not, attempt to re-launch the script with elevated credentials
If ( !$ElevatedTest )
{
	$CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
	Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
	Exit
}

# Abort if wpr.exe is not found
If ( !$WPRTest )
{
	Write-Warning "$WPR not found."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Write-Warning "This script requires wpr.exe to run."
	Return "Exiting script"
}

# Abort if we are not running Windows 10 or later, wpr.exe does not exist on releases before Windows 10
If ( $WindowsBuild -lt $MinimumBuild )
{
	Write-Warning "This script can only run on Windows 10+"
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Write-Warning "This script only supports builds $MinimumBuild and greater. Detected Windows build: $WindowsBuild."
	Return "Exiting script"
}

Start-Transcript -Path $TranscriptPath -Force | Out-Null
Write-Output $VersionString

# Ensure that wpr.exe is not already running a trace, as it can only run one trace at a time
$WPRStatus = &$WPR -Status | Select-Object -Last 1

If ( $WPRStatus -ne "WPR is not recording" )
{
	Write-Output "wpr.exe is already running a trace, attempting to cancel it..."
	&$WPR -Cancel 2> $null
}
	
# Prompt user to choose what profiles to use
$Form               = New-Object System.Windows.Forms.Form 
$Form.Text          = "WPR Profile Selection"
$Form.Size          = New-Object System.Drawing.Size(300,440) 
$Form.StartPosition = "CenterScreen"

$OkButton 			   = New-Object System.Windows.Forms.Button
$OkButton.Location     = New-Object System.Drawing.Point(50,370)
$OkButton.Size         = New-Object System.Drawing.Size(75,23)
$OkButton.Text         = "OK"
$OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

$Form.AcceptButton = $OkButton
$Form.Controls.Add($OkButton)

$CancelButton              = New-Object System.Windows.Forms.Button
$CancelButton.Location     = New-Object System.Drawing.Point(170,370)
$CancelButton.Size         = New-Object System.Drawing.Size(75,23)
$CancelButton.Text         = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

$Form.CancelButton = $CancelButton
$Form.Controls.Add($CancelButton)

$Label          = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(10,20) 
$Label.Size     = New-Object System.Drawing.Size(280,20) 
$Label.Text     = "Select one or more profiles from the list:"
$Form.Controls.Add($Label) 

$ListBox               = New-Object System.Windows.Forms.Listbox 
$ListBox.Location      = New-Object System.Drawing.Point(10,40) 
$ListBox.Size          = New-Object System.Drawing.Size(260,20) 
$ListBox.SelectionMode = "MultiExtended"
$ListBox.Height        = 320

# Create a selectable item in the listBox for every entry in $ValidProfiles array.
ForEach ( $Profile in $ValidProfiles )
{
	[void] $ListBox.Items.Add($Profile)
}

$Form.Controls.Add($ListBox) 
$Form.Topmost = $True
$Result       = $Form.ShowDialog()

$SelectedProfiles = $ListBox.SelectedItems
	
# If the user pressed cancel or closed the window, or if the user selected 0 items and pressed OK, abort the script
If ( ($Result -ne [System.Windows.Forms.DialogResult]::OK) -or !$SelectedProfiles )
{		
	Write-Warning "No profiles selected, exiting script."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Exit
}
	
# The user selected 1 or more profiles and pressed OK, print their selection and continue
Write-Output "Selected Trace Profile(s):"
$SelectedProfiles

ForEach ( $Profile in $SelectedProfiles )
{
	$WPRArguments += "-Start $Profile "
}

# Prompt user for amount of time (in minutes) the collection should run
$Form               = New-Object System.Windows.Forms.Form 
$Form.Text          = "Trace duration"
$Form.Size          = New-Object System.Drawing.Size(300,200) 
$Form.StartPosition = "CenterScreen"

$OkButton              = New-Object System.Windows.Forms.Button
$OkButton.Location     = New-Object System.Drawing.Point(75,120)
$OkButton.Size         = New-Object System.Drawing.Size(75,23)
$OkButton.Text         = "OK"
$OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

$Form.AcceptButton = $OkButton
$Form.Controls.Add($OkButton)

$CancelButton              = New-Object System.Windows.Forms.Button
$CancelButton.Location     = New-Object System.Drawing.Point(150,120)
$CancelButton.Size         = New-Object System.Drawing.Size(75,23)
$CancelButton.Text         = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

$Form.CancelButton = $CancelButton
$Form.Controls.Add($CancelButton)

$Label          = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(10,20) 
$Label.Size     = New-Object System.Drawing.Size(280,20) 
$Label.Text     = "Time, in seconds, that the trace will run ($LowerTimeLimitSeconds-$UpperTimeLimitSeconds)"
$Form.Controls.Add($Label) 

$TextBox          = New-Object System.Windows.Forms.TextBox 
$TextBox.Location = New-Object System.Drawing.Point(10,40) 
$TextBox.Size     = New-Object System.Drawing.Size(260,20) 
$Form.Controls.Add($TextBox) 

$Form.Topmost = $True

$Form.Add_Shown({$TextBox.Select()})
$Result = $Form.ShowDialog()
	
# Ensure the input is an integer, otherwise this will set $TimeLimitSeconds to $null
$TimeLimitSeconds = $TextBox.Text -as [int]

Write-Output "Trace will run for $TimeLimitSeconds seconds."
	
# If the user pressed cancel or closed the window, abort the script
If ( $Result -ne [System.Windows.Forms.DialogResult]::OK )
{
	Write-Warning "Input box was closed or canceled."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Exit
}

# If the user entered nothing or an invalid string and pressed OK, abort the script
If ( !$TimeLimitSeconds )
{
	Write-Warning "An invalid time value was entered."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Exit
}

# If the entered amount is out of range, abort the script
If ( !($TimeLimitSeconds -in $ValidTimeRange) )
{	
	Write-Warning "Time limit must be between $LowerTimeLimitSeconds and $UpperTimeLimitSeconds seconds."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Exit
}
	  
# Prompt user to choose where to place the output
Write-Output "Select the output folder for the trace file."
$FolderBrowser             = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select the output folder for the trace file."
[void]$FolderBrowser.ShowDialog()

$SelectedFolder = $FolderBrowser.SelectedPath

If ( !$SelectedFolder )
{
	Write-Warning "No path selected."
	Exit
}

If ( !(Test-Path -Path $SelectedFolder -PathType Container) )
{
	Write-Warning "$SelectedFolder is not a valid directory."
	Stop-Transcript | Out-Null
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Exit
}

Write-Output "Selected output path: $SelectedFolder"
$OutputPath = Join-Path -Path $SelectedFolder -ChildPath $ZipName
	
# Start wpr.exe with the selected profiles
Write-Output "Running ETW trace for $TimeLimitSeconds seconds..."
Start-Process -FilePath $WPR -ArgumentList $WPRArguments -NoNewWindow
	
# Wait for the specified amount of time before stopping the trace
Start-Sleep -Seconds $TimeLimitSeconds

# Once timelimit has been reached, stop trace and generate the .etl file
Write-Output "Generating trace file..."
&$WPR -Stop $TempETLPath

# Wait for symbols to be generated, remove them
Write-Output "Waiting for symbol generation..."
Start-Sleep -Seconds 5

If ( (Test-Path -Path $SymbolPath) -eq $True -and $KeepPDB -ne $True )
{
	Remove-Item -Recurse -Path $Symbolpath -Force 2> $null | Out-Null
}

Stop-Transcript | Out-Null
Compress-Archive -Path "$TempOutputPath\*" -DestinationPath $OutputPath -CompressionLevel Optimal -Force

If ( $? -eq "True" -and (Test-Path -Path $OutputPath) -eq $True )
{
	Remove-Item -Recurse -Path $TempOutputPath -Force | Out-Null
	Write-Output "Script complete, output: $OutputPath"
}

Else
{
	Write-Warning "Compression failed"
	Write-Output "Script complete, output: $TempOutputPath"
}

Read-Host "Press Enter to close this window."