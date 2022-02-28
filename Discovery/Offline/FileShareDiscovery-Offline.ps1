<#

  _____            ___  
 |  __ \          / _ \ 
 | |__) |_ ___  _| (_) |
 |  ___/ _` \ \/ /> _ < 
 | |  | (_| |>  <| (_) |
 |_|   \__,_/_/\_\\___/ 


.NAME
    Pax8 File Share Discovery - Legacy
.SYNOPSIS
    This legacy tool will work on machines where the .Net framework cannot be properly updated,
    or the tool is running in an "offline" mode and cannot connect to the internet to install necessary modules.
    It will run as a console app to gather file share information in preparation of migration and export to CSV files.
.DESCRIPTION
    Find Size of the "root" folders in file share
    Gathers all files and folders in file share [ ListOf-AllFiles.csv ]
    Find long file paths
    Find ALL unique folder paths [ ListOf-UniqueFolders.csv ] 
    Gather NTFS Security Permissions [ ListOf-NtfsPermissions.csv ]
Changes made during script run:
  - Creates folder 'C:\TempPax8'
  - Collects ExecutionPolicy, sets ExecutionPolicy to ByPass and sets back to original at the end of script

MUST RUN SCRIPT AS ADMINISTRATOR!

REVISED:  9/17/2021

#>

## Get Execution Policy to setback at end of script
$varExecPolicy = Get-ExecutionPolicy

## Change Execution Policy for Script run
Set-ExecutionPolicy -ExecutionPolicy ByPass -Force

### REVISION DATE -- WILL BE DISPLAYED IN FORM!
$RevDate = "9/17/2021"

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
$varmsg = "OPERATION: File Share Discovery Script (Legacy Script: Offline/Outdated Systems) | Script Revised: " + $RevDate
if ($log -eq $true) { "`n$($varmsg)" | Add-Content $logFile }

###################################################################
#            INVENTORY FUNCTIONS                                  #
###################################################################

## Function 1
function Get-AllFiles {
    try {
    $varAllFiles = Get-ChildItem $FileSharePath -recurse -ErrorAction Stop | where { $_.DirectoryName -ne $NULL } | select-object { $_.FullName }
    $varAllFiles | select-object { $_.FullName } | Export-CSV $TempDir\ListOf-AllFiles.csv -Force
        }
    catch {
        $AllFilesError = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($AllFilesError)" | Add-Content $logFile }
    }

}

## Function 2
function Get-NTFSPermissions {
    try {
    $varPermissions = Get-Childitem -path $FileSharePath -recurse -ErrorAction Stop | Where-Object {$_.PSIsContainer} | Get-ACL | Select-Object Path -ExpandProperty Access
    $varPermissions | Export-CSV $TempDir\ListOf-NtfsPermissions.csv -Force
        }
    catch {
        $PermissionError = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($PermissionError)" | Add-Content $logFile }
}
}

## Function 3
function Get-UniqueFolders {
   
    # Initialize the arrays to hold our items
    $dirmap = @()
    $items = @()

    #Build a temp the array to hold all the items
    try {
        $items += @(Get-ChildItem $FileSharePath -Recurse -Name -Directory)
        }
    catch {
        $msg14error = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($msg14error)" | Add-Content $logFile }
        }

    # Loop through the array so we can clean up the path name
    foreach ($i in $items) {
        # Fill up our main array with the full path name
        try {
            $dirmap += @($FileSharePath.text + "\" + $i) 
            }
        catch {
        $FolderError = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($FolderError)" | Add-Content $logFile }
        }
    }

    $dirmap | Out-File $TempDir\ListOf-UniqueFolders.csv -Force
    }


## Function 4
function Get-LongFilePaths {
    try {
    $varLongFiles = Get-ChildItem $FileSharePath -recurse -force -ErrorAction Stop | where-object { $_.FullName.Length -ge 255 } | select-object FullName
    $varLongFiles | Export-CSV $TempDir\ListOf-LongFilePaths.csv
        }
    catch {
        $LongPathError = " ## Error: " + $_.Exception.Message + " - $(Get-TimeStamp)"
        if ($log -eq $true) { "`n$($LongPathError)" | Add-Content $logFile }
        }
}

## Function 5
function Get-RootFolderSizes {

    Param (
    [Parameter(ValueFromPipeline)]
	[string[]]$Paths = $FileSharePath,
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
    $HTML = $Report | Select 'Folder Name',Owner,'Created On','Last Updated',Size | Sort $SortBy -Descending:$Descending | ConvertTo-Html -PreContent $Pre -PostContent $Post -Head $Header | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-File $TempDir\FileShare_FolderSizes.html
    
    Write-Verbose "$(Get-Date): $NumDirs folders processed"
    Write-Verbose "$(Get-Date): Script completed!"

}
}

## Inventory Functions
function AdminExecute { 
    ## Begin Inventory
    Write-Host " "
    Write-Host "  *** " -f Yellow -NoNewline
    Write-Host "Beginning Discovery on File Share" -f Green -NoNewline
    Write-Host " ***" -f Yellow -NoNewLine
    Write-Host "      "$(Get-TimeStamp)
    $msgBegin = "*** Beginning Discovery on File Share *** - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgBegin)" | Add-Content $logFile }

    ## Pause Briefly
    Start-Sleep -Seconds 2

    # 1) Find Size of the "root" folders in file share
    $msgStep1 = "    ---  Gathering root folder sizes [1 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgStep1)" | Add-Content $logFile }
    Write-Host " "
    Write-Host $msgStep1
    ## Function Call
    Get-RootFolderSizes

    ## Pause Briefly
    Start-Sleep -Seconds 3

    # 2) Find ALL Files on file share
    $msgStep2 = "    ---  Finding all files on File Share [2 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgStep2)" | Add-Content $logFile }
    Write-Host " "
    Write-Host $msgStep2
    ## Function Call
    Get-AllFiles

    ## Pause Briefly
    Start-Sleep -Seconds 3
        
    # 3) Gather NTFS Security Permissions
    $msgStep3 = "    ---  Gathering NTFS Security Permissions [3 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgStep3)" | Add-Content $logFile }
    Write-Host " "
    Write-Host $msgStep3
    ## Function Call
    Get-NTFSPermissions

    ## Pause Briefly
    Start-Sleep -Seconds 3

    # 4) Find ALL unique folder paths
    $msgStep4 = "    ---  Finding unique folder paths [4 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgStep4)" | Add-Content $logFile }
    Write-Host " "
    Write-Host $msgStep4
    ## Function Call
    Get-UniqueFolders

    ## Pause Briefly
    Start-Sleep -Seconds 3

    # 5) Find long file paths
    $msgStep5 = "    ---  Finding long file paths [5 of 5] - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgStep5)" | Add-Content $logFile }
    Write-Host " "
    Write-Host $msgStep5
    ## Function Call
    Get-LongFilePaths

    ## Pause Briefly
    Start-Sleep -Seconds 3

    #Inform users that discovery completed
    ## END File Share Inventory
    Write-Host " "
    Write-Host "  *** " -f Yellow -NoNewline
    Write-Host "File Share Discovery Completed" -f Green -NoNewline
    Write-Host " ***" -f Yellow -NoNewLine
    Write-Host "      "$(Get-TimeStamp)
    $msgEnd = "*** File Share Discovery Completed *** - $(Get-TimeStamp)"
    if ($log -eq $true) { "`n$($msgEnd)" | Add-Content $logFile }
    Write-Host " "
    Write-Host " "
    Write-Host "  This window will close momentarily...  - $(Get-TimeStamp)"

    ## Pause Briefly
    Start-Sleep -Seconds 3
    
    #Open Explorer to $exportdirectory
    explorer.exe $TempDir

    ## Cleanup -- Set Execution Policy back
    Set-ExecutionPolicy -ExecutionPolicy $varExecPolicy -Force

    ## Pause Briefly
    Start-Sleep -Seconds 7
}

###################################################################
#            BUILD TEXT INTERFACE                                 #
###################################################################

## Clear Screen of any current text
CLS

## Build Layout
Write-Host "  Rev. " -f Green -NoNewline
Write-Host $RevDate
Write-Host "   ____________________________________"
Write-Host "  |" -NoNewline
Write-Host "       _____            ___         " -f Green -NoNewline
Write-Host "|" -f White

Write-Host "  |" -NoNewline
Write-Host "      |  __ \          / _ \        " -f Green -NoNewline
Write-Host "|"

Write-Host "  |" -NoNewline
Write-Host "      | |__) |_ ___  _| (_) |       " -f Green -NoNewline
Write-Host "|"

Write-Host "  |" -NoNewline
Write-Host "      |  ___/ _' \ \/ /> _ <        " -f Green -NoNewline
Write-Host "|"

Write-Host "  |" -NoNewline
Write-Host "      | |  | (_| |>  <| (_) |       " -f Green -NoNewline
Write-Host "|"

Write-Host "  |" -NoNewline
Write-Host "      |_|   \__,_/_/\_\\___/        " -f Green -NoNewline
Write-Host "|"
Write-Host "  |                                    |"
Write-Host "  |" -NoNewline
Write-Host "  **" -f Green -NoNewline
Write-Host " File Share Discovery Tool " -BackgroundColor White -ForegroundColor Black -NoNewline
Write-Host "**" -f Green -NoNewline
Write-Host "   |"
Write-Host "  |     [" -NoNewline
Write-Host "Legacy" -f Yellow -NoNewline
Write-Host "/" -NoNewline
Write-Host "Offline" -f Yellow -NoNewline
Write-Host " Version]       |"
Write-Host "  |____________________________________|"
Write-Host " "
Write-Host " "

###################################################################
#            BEGIN SCRIPT EXECUTION                               #
###################################################################

Write-Host " "
Write-Host "  ** Did you start this app by running 'As Administrator'? **" -f Yellow
Write-Host "  ##" -f Red -NoNewline
Write-Host " Please Close this app and re-run as an Administrator to get the most accurate inventory. " -f White -NoNewline
Write-Host "##" -f Red

## Capture File Share Path
Write-Host " "
Write-Host "  Enter the File Share Path Below (ex. D:\Files, \\Server\ShareName, P:\, \\10.0.0.20\ShareName)"
Write-Host " "
$FileSharePath = Read-Host "  --- File Share Path ---> "
$msgPath = "File Share Path is logged as: " + $FileSharePath + " - $(Get-TimeStamp)"
if ($log -eq $true) { "`n$($msgPath)" | Add-Content $logFile }
## Call Function
AdminExecute


## END OF SCRIPT