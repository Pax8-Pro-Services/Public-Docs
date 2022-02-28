<#

  _____            ___  
 |  __ \          / _ \ 
 | |__) |_ ___  _| (_) |
 |  ___/ _` \ \/ /> _ < 
 | |  | (_| |>  <| (_) |
 |_|   \__,_/_/\_\\___/ 


.NAME
    Pax8 File Share Discovery
.SYNOPSIS
    Tool to gather file share information in preparation of migration
.DESCRIPTION
    Find Size of the "root" folders in file share
    Gathers all files and folders in file share
    Find long file paths
    Find ALL unique folder paths
    Gather NTFS Security Permissions
Changes made during script run:
  - Creates folder 'C:\TempPax8'
  - Allow connections to HTTPS
  - Sets MS PowerShell Gallery as trusted repository
  - Collects ExecutionPolicy, sets ExecutionPolicy to ByPass and sets back to original at the end of script
  - Installs NuGet Package Manager at the Current User scope
  - Instals PS Module 'ImportExcel' at Current User Scope to allow exporting discovery to single XLSX file

REVISED: 9/17/2021
Newest Revisions:
 - Fix error trapping
    (ErrorAction Continue) to keep running script

MUST RUN SCRIPT AS ADMINISTRATOR!

#>

## Sets PowerShell to use HTTPS connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

## Sets Microsoft PowerShell Gallery as Trusted install source
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

## Get Execution Policy to setback at end of script
$varExecPolicy = Get-ExecutionPolicy

## Change Execution Policy for Script run
Set-ExecutionPolicy -ExecutionPolicy ByPass -Force

### REVISION DATE -- WILL BE DISPLAYED IN FORM!
$RevDate = "9/17/2021"

## SCRIPT VARIABLES
#$Test1 = "Replace test ver 1"

## Temp Directory
$TempDir = "C:\TempPax8"

## Log ON ($true) or OFF ($false)
$log = $true

###################################################################
#            SCRIPT FUNCTIONS                                     #
###################################################################



## TIME STAMP FUNCTION
function Get-TimeStamp {
    
    return "[ {0:MM/dd/yy} {0:HH:mm:ss} ]" -f (Get-Date)
    
}

## Function to Check if directory exists, and create if it does not
if (-not (Test-Path -LiteralPath $TempDir)) {
    
    try {
        New-Item -Path $TempDir -ItemType Directory -ErrorAction Stop | Out-Null #-Force
    }
    catch {
        Write-Error -Message "Unable to create directory '$TempDir'. Error was: $_" -ErrorAction Stop
    }
    "Successfully created directory '$TempDir'."

}
else {
    "Directory already exists."
}


## Set Current Working Directory
Set-Location -Path $TempDir -PassThru

###################################################################
#            LOGGING OPERATIONS                                   #
###################################################################

if ($log -eq $true)

{

  ## Construct a log file name based on the date that
  ## we can save progress to
  $logStart = Get-Date
  $logStartDate = "$($logStart.Year)-$($logStart.Month)-$($logStart.Day)"
  $logStartTime = "$($logStart.Hour)-$($logStart.Minute)-$($logStart.Second)"
  $logFile = ".\FileShareInventoryLog_" + $logStartDate + "-" + $logStartTime + ".txt"

}

## Log Header
$varmsg = "OPERATION: File Share Discovery Script (GUI Form) | Script Revised: " + $RevDate
if ($log -eq $true) { "`n$($varmsg)" | Add-Content $logFile }


###################################################################
#            INSTALL AND CHECK MODULE AVAILABILTY                 #
###################################################################

## Install NuGet Modules -- For Installing Packages
Try {

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop
    $NuGetmsg1 = "-- Installing Nuget Package Manager - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($NuGetmsg1)" | Add-Content $logFile }
    CLS

}
    Catch {
    $NuGetmsg2 = " ## Error Installing module. " + $_.Exception.Message + " - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($NuGetmsg2)" | Add-Content $logFile }

}

## Install ImportExcel Module -- For exporting discovery results to XLSX file
Try {
    
    $msg1a = "-- Attempting ImportExcel Module Install - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg1a)" | Add-Content $logFile }
    Install-Module ImportExcel -Scope CurrentUser -ErrorAction Stop
    $msg1b = "-- ImportExcel Module Installed Successfully - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg1b)" | Add-Content $logFile }
    Import-Module ImportExcel
    $msg1c = "-- ImportExcel Module Imported Successfully - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg1c)" | Add-Content $logFile }

    }

    Catch {
    $msg2 = " ## Error Installing module. " + $_.Exception.Message + " - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg2)" | Add-Content $logFile }
    #write-host $msg2 -f Red 
    }


## Check if ImportExcel Module is installed correctly, set output variable
if (Get-Module -ListAvailable -Name ImportExcel) {
  $ScriptOutPax8 = "Excel"
  $msg3 = "-- ImportExcel Module EXISTS - Setting Output Variable to EXCEL - $(Get-TimeStamp)"
  if ($log -eq $true) { "`n$($msg3)" | Add-Content $logFile }
  Write-Host "Module exists"
}
else {
  $ScriptOutPax8 = "csv"
  $msg4 = "-- Cannot find the module: 'ImportExcel' - Setting Output Variable to CSV - $(Get-TimeStamp)"
  if ($log -eq $true) { "`n$($msg4)" | Add-Content $logFile }
  }


## TEST
$msgTest1 = "-- SCRIPT OUTPUT VARIABLE: " + $ScriptOutPax8 + " - $(Get-TimeStamp)"
if ($log -eq $true) { "`n$($msgTest1)" | Add-Content $logFile }

###################################################################
#            INVENTORY FUNCTIONS                                  #
###################################################################

## Function 1
function Get-AllFiles {
    try {
    $varAllFiles = Get-ChildItem $FS.text -recurse -ErrorAction Continue | where { $_.DirectoryName -ne $NULL } | select-object { $_.FullName }
        }
    catch {
        $msg12error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg12error)" | Add-Content $logFile }
    }

    if ($ScriptOutPax8 -eq "Excel") {
        Import-Module ImportExcel
        $varAllFiles | Export-Excel -Path $dirmapFile -AutoSize -TableName "AllFiles" -WorksheetName "ALL Files" -Append
    }
    else {
        $varAllFiles | select-object { $_.FullName } | Export-CSV $exportdirectory\ListOf-AllFiles.csv
    }
}

## Function 2
function Get-NTFSPermissions {
    try {
    $varPermissions = Get-Childitem -path $FS.text -recurse -ErrorAction Continue | Where-Object {$_.PSIsContainer} | Get-ACL | Select-Object Path -ExpandProperty Access
        }
    catch {
        $msg13error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg13error)" | Add-Content $logFile }
    }
    if ($ScriptOutPax8 -eq "Excel") {
        Import-Module ImportExcel
        $varPermissions | Export-Excel -Path $dirmapFile -AutoSize -TableName "AllNTFSPermissions" -WorksheetName "ALL NTFS Permissions" -Append
            
    }
    else {
        $varPermissions | Export-CSV $exportdirectory\ListOf-NtfsPermissions.csv
    }
}

## Function 3
function Get-UniqueFolders {
   
    # Initialize the arrays to hold our items
    $dirmap = @()
    $items = @()

    #Build a temp the array to hold all the items
    try {
        $items += @(Get-ChildItem $FS.text -Recurse -Name -Directory)
        }
    catch {
        $msg14error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg14error)" | Add-Content $logFile }
        }

    # Loop through the array so we can clean up the path name
    foreach ($i in $items) {
        # Fill up our main array with the full path name
        try {
            $dirmap += @($FS.text + "\" + $i) 
            }
        catch {
        $msg15error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg15error)" | Add-Content $logFile }
        }
    }

    # Create a CSV ro Excel file from the array
    if ($ScriptOutPax8 -eq "Excel") {
    Import-Module ImportExcel
    $dirmap | Export-Excel -Path $dirmapFile -AutoSize -TableName "AllFolders" -WorksheetName "ALL Unique Folders" -Append
    }
    else {
    $dirmap | Out-File $exportdirectory\ListOf-UniqueFolders.csv -Force
    }
}

## Function 4
function Get-LongFilePaths {
    try {
    $varLongFiles = Get-ChildItem $FS.text -recurse -force -ErrorAction Continue | where-object { $_.FullName.Length -ge 255 } | select-object FullName
        }
    catch {
        $msg16error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg16error)" | Add-Content $logFile }
        }

    if ($ScriptOutPax8 -eq "Excel") {
        Import-Module ImportExcel
        $varLongFiles | Export-Excel -Path $dirmapFile -AutoSize -TableName "LongFilePaths" -WorksheetName "Long File Paths" -Append
        }
    else {
        $varLongFiles | Export-CSV $exportdirectory\ListOf-LongFilePaths.csv
         }
}

## Function 5
function Get-RootFolderSizes {

    Param (
    [Parameter(ValueFromPipeline)]
	[string[]]$Paths = $FS.text,
	[string]$ReportPath = $TempDir,
    [ValidateSet("Folder","Folders","Size","Created","Changed","Owner")]
    [string]$Sort = "Folder",
    [switch]$Descending,
    [switch]$Recurse
)

Begin {
    Function AddObject {
    	Param ( 
    		$FileObject
    	)
        #$RawSize = (Get-ChildItem $FileObject.FullName -Recurse | Measure-Object Length -Sum).Sum
        $RawSize = (Get-ChildItem $FileObject.FullName -Recurse | Where-Object { -not $_.PSIsContainer } | Measure-Object -property Length -Sum).Sum 

    	If ($RawSize)
    	{	$Size = CalculateSize $RawSize
    	}
    	Else
    	{	$Size = "0.00 MB"
    	}
    	$Object = New-Object PSObject -Property @{
    		'Folder Name' = $FileObject.FullName
    		'Created on' = $FileObject.CreationTime
    		'Last Updated' = $FileObject.LastWriteTime
    		Size = $Size
    		Owner = (Get-Acl $FileObject.FullName).Owner
            RawSize = $RawSize
    	}
        Return $Object
    }

    Function CalculateSize {
    	Param (
    		[double]$Size
    	)
    	If ($Size -gt 1000000000)
    	{	$ReturnSize = "{0:N2} GB" -f ($Size / 1GB)
    	}
    	Else
    	{	$ReturnSize = "{0:N2} MB" -f ($Size / 1MB)
    	}
    	Return $ReturnSize
    }

    Function Set-AlternatingRows {
        [CmdletBinding()]
       	Param(
           	[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
            [object[]]$Lines,
           
       	    [Parameter(Mandatory=$True)]
           	[string]$CSSEvenClass,
           
            [Parameter(Mandatory=$True)]
       	    [string]$CSSOddClass
       	)
    	Begin {
    		$ClassName = $CSSEvenClass
    	}
    	Process {
            ForEach ($Line in $Lines)
            {	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
        		If ($ClassName -eq $CSSEvenClass)
        		{	$ClassName = $CSSOddClass
        		}
        		Else
        		{	$ClassName = $CSSEvenClass
        		}
        		Return $Line
            }
    	}
    }

    #Validate sort parameter
    Switch -regex ($Sort)
    {   "^folder.?$" { $SortBy = "Folder Name";Break }
        "created" { $SortBy = "Created On";Break }
        "changed" { $SortBy = "Last Updated";Break }
        default { $SortBy = $Sort }
    }
            
    $Report = @()
    $TotalSize = 0
    $NumDirs = 0
    $Title = @()
    Write-Verbose "$(Get-Date): Script begins!"
}

Process {
    ForEach ($Path in $Paths)
    {   #Test if path exists
        If (-not (Test-Path $Path))
        {   $Result += $Object = New-Object PSObject -Property @{
        		'Folder Name' = $Path
        		'Created on' = ""
        		'Last Updated' = ""
        		Size = ""
        		Owner = "Path not found"
                RawSize = 0
        	}
            $Title += $Path
            Continue
        }
            
        #First get the properties of the starting path
        $NumDirs ++
        Write-Verbose "$(Get-Date): Now working on $Path..."
        $Root = Get-Item -Path $Path 
        $Result = AddObject $Root
        $TotalSize += $Result.RawSize
        $Report += $Result
        $Title += $Path

        #Now loop through all the subfolders
        $ParamSplat = @{
            Path = $Path
            Recurse = $Recurse
        }
        ForEach ($Folder in (Get-ChildItem @ParamSplat | Where { $_.PSisContainer }))
        {	$Report += AddObject $Folder
            $NumDirs ++
        }
    }
}

End {
    #Create the HTML for our report
    $Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<Title>
Folder Sizes for "$Path"
</Title>
"@

    $TotalSize = CalculateSize $TotalSize

    $Pre = "<h1>Folder Sizes Report</h1><h3>Folders processed: ""$($Title -join ", ")""</h3>"
    $Post = "<h2><p>Total Folders Processed: $NumDirs<br>Total Space Used:  $TotalSize</p></h2>Run on $(Get-Date -f 'MM/dd/yyyy hh:mm:ss tt')</body></html>"

    #Create the report and save it to a file
    $HTML = $Report | Select 'Folder Name',Owner,'Created On','Last Updated',Size | Sort $SortBy -Descending:$Descending | ConvertTo-Html -PreContent $Pre -PostContent $Post -Head $Header | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-File $exportdirectory\FileShare_FolderSizes.html
    
    Write-Verbose "$(Get-Date): $NumDirs folders processed"
    Write-Verbose "$(Get-Date): Script completed!"
       
    $wshell = New-Object -ComObject Wscript.Shell

    #$wshell.Popup("Operation Completed, please close ",0,"Done",0x1)


}
}


###################################################################
#            BUILD GUI FORM                                       #
###################################################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Discover = New-Object system.Windows.Forms.Form
$Discover.ClientSize = New-Object System.Drawing.Point(410, 400)
$Discover.text = "Pax8 File Share Discovery"
$Discover.TopMost = $true
$Discover.StartPosition = 'CenterScreen'

$DiscoButton = New-Object system.Windows.Forms.Button
$DiscoButton.text = "Click to Discover!"
$DiscoButton.width = 225
$DiscoButton.height = 30
$DiscoButton.location = New-Object System.Drawing.Point(35, 285)
$DiscoButton.Font = New-Object System.Drawing.Font('Century Gothic', 10)

$CloseButton = New-Object system.Windows.Forms.Button
$CloseButton.text = "CLOSE"
$CloseButton.width = 75
$CloseButton.height = 30
$CloseButton.location = New-Object System.Drawing.Point(290, 285)
$CloseButton.Font = New-Object System.Drawing.Font('Century Gothic', 10, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$CloseButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")
$CloseButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$Discover.CancelButton = $CloseButton

$LogoPax8 = New-Object system.Windows.Forms.PictureBox
$LogoPax8.width = 146
$LogoPax8.height = 94
$LogoPax8.location = New-Object System.Drawing.Point(132, 16)
$LogoPax8.imageLocation = "https://www.pax8.com/en-us/wp-content/uploads/sites/4/cache/2020/04/pax8-logo-2-color-dark-200x200-cropped.png"
$LogoPax8.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::zoom

$LabelRev = New-Object system.Windows.Forms.Label
$LabelRev.text = "Revised:"
$LabelRev.AutoSize = $true
$LabelRev.width = 20
$LabelRev.height = 10
$LabelRev.location = New-Object System.Drawing.Point(10, 15)
$LabelRev.Font = New-Object System.Drawing.Font('Century Gothic', 8)

$LabelRevDate = New-Object system.Windows.Forms.Label
$LabelRevDate.text = $RevDate
$LabelRevDate.AutoSize = $true
$LabelRevDate.width = 25
$LabelRevDate.height = 10
$LabelRevDate.location = New-Object System.Drawing.Point(60, 15)
$LabelRevDate.Font = New-Object System.Drawing.Font('Century Gothic', 8)

$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "File Share Discovery"
$Label2.AutoSize = $true
$Label2.width = 25
$Label2.height = 10
$Label2.location = New-Object System.Drawing.Point(53, 140)
$Label2.Font = New-Object System.Drawing.Font('Century Gothic', 24)

$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Please enter the path of fileshare to be migrated:"
$Label3.AutoSize = $true
$Label3.width = 25
$Label3.height = 10
$Label3.location = New-Object System.Drawing.Point(47, 185)
$Label3.Font = New-Object System.Drawing.Font('Century Gothic', 10)

$Label4 = New-Object system.Windows.Forms.Label
$Label4.text = "[ ex. D:\Files, \\server\share, P:\ ]"
$Label4.AutoSize = $true
$Label4.width = 25
$Label4.height = 10
$Label4.location = New-Object System.Drawing.Point(85, 211)
$Label4.Font = New-Object System.Drawing.Font('Century Gothic', 10)

$Label5 = New-Object system.Windows.Forms.Label
$Label5.text = "DISCOVERY STATUS:"
$Label5.AutoSize = $true
$Label5.width = 75
$Label5.height = 8
$Label5.location = New-Object System.Drawing.Point(15, 340)
$Label5.Font = New-Object System.Drawing.Font('Century Gothic', 8)

$Label6 = New-Object system.Windows.Forms.Label
$Label6.text = "...Ready!"
$Label6.AutoSize = $true
$Label6.width = 75
$Label6.height = 10
$Label6.location = New-Object System.Drawing.Point(15, 360)
$Label6.Font = New-Object System.Drawing.Font('Century Gothic', 10)

$FS = New-Object system.Windows.Forms.TextBox
$FS.multiline = $false
$FS.width = 330
$FS.height = 20
$FS.location = New-Object System.Drawing.Point(36, 240)
$FS.Font = New-Object System.Drawing.Font('Century Gothic', 10)

$Discover.controls.AddRange(@($DiscoButton, $CloseButton, $LogoPax8, $LabelRev, $LabelRevDate, $Label2, $Label3, $Label4, $FS, $Label5, $Label6))

$exportdirectory = $TempDir
$dirmapFile = ".\FileShare_Discovery.xlsx"

$DiscoButton.Add_Click( { Execute })

###################################################################
#            SCRIPT EXECUTE                                       #
###################################################################

function Execute { 
    ## Begin Inventory
    $msg5 = "*** Beginning Discovery on File Share *** - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg5)" | Add-Content $logFile }
    ## Post back to form status
    $Label6.Text = "File Share Discovery In Progress..."

    Write-Host $msg5
    
    #Create export directory if needed
    if (-not (test-path $exportdirectory)) {
        md $exportdirectory | out-null
    }
    ## Pause Briefly
    Start-Sleep -Seconds 5

    # 1) Find Size of the "root" folders in file share
    $msg10 = "  ---  Gathering root folder sizes [1 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg10)" | Add-Content $logFile }
    $Label6.text = "  ---  Gathering root folder sizes"
    Write-Host $msg10
    ## Function Call
    Get-RootFolderSizes

    # 2) Find ALL Files on file share
    $msg6 = "  ---  Finding all files on File Share [2 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg6)" | Add-Content $logFile }
    $Label6.text = "  ---  Finding all files on File Share"
    Write-Host $msg6
    ## Function Call
    Get-AllFiles

    ## Pause Briefly
    Start-Sleep -Seconds 5
        
    # 3) Gather NTFS Security Permissions
    $msg7 = "  ---  Gathering NTFS Security Permissions [3 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg7)" | Add-Content $logFile }
    $Label6.text = "  ---  Gathering NTFS Security Permissions"
    Write-Host $msg7
    ## Function Call
    Get-NTFSPermissions

    ## Pause Briefly
    Start-Sleep -Seconds 5

    # 4) Find ALL unique folder paths
    $msg8 = "  ---  Finding unique folder paths [4 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg8)" | Add-Content $logFile }
    $Label6.text = "  ---  Finding unique folder paths"
    Write-Host $msg8
    ## Function Call
    Get-UniqueFolders

    ## Pause Briefly
    Start-Sleep -Seconds 5

    # 5) Find long file paths
    $msg9 = "  ---  Finding long file paths [5 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg9)" | Add-Content $logFile }
    $Label6.text = "  ---  Finding long file paths"
    Write-Host $msg9
    ## Function Call
    Get-LongFilePaths

    ## Pause Briefly
    Start-Sleep -Seconds 5





    #Inform users that discovery completed
    ## END File Share Inventory
    Write-Host "*** " -f Yellow -NoNewline
    Write-Host "File Share Discovery Completed" -f Green -NoNewline
    Write-Host " ***" -f Yellow -NoNewLine
    Write-Host "      "$(Get-TimeStamp)
    $msg11 = "*** File Share Discovery Completed *** - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msg11)" | Add-Content $logFile }
    $Label6.text = "Discovery Completed! PLEASE CLOSE WINDOW TO EXIT!"
    #Write-Host $msg11

    ## Cleanup -- Set Execution Policy back
    Set-ExecutionPolicy -ExecutionPolicy $varExecPolicy -Force
    
    #Open Explorer to $exportdirectory
    explorer.exe $exportdirectory
}





[void]$Discover.ShowDialog()

