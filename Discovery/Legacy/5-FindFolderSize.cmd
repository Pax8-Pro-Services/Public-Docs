echo off
Title Pax8 File Share Discovery -- File Share Size
::echo on
::==================================================================================
:: LIST FOLDER SIZE
:: A script to list folder size on directory 
::  Description:
::   - Creates a temp directory for file output called 'C:\TempPax8'
::   - Promptes for local file share path
::   - Exports contents to C:\TempPax8\get_AllFolders.txt
::
:: Revised: 6/6/2021
::==================================================================================

echo ==================================================================================
echo  LIST FOLDER SIZE
echo  Revised: 6/6/2021
echo 
echo ==================================================================================
:: Create Folder
md C:\TempPax8
echo 
echo Enter the local directory of the file share.
echo Ex. D:\Share or E:\Data\Share
set /p ShareData=Enter Path:  
echo Search directory is: %ShareData%
:: Change to working file share directory entered
CD /D %ShareData%


set "Folder=%ShareData%"
Set Log=C:\TempPax8\Folder_Size.txt 
(
    echo The size of "%Folder%" is 
    Call :GetSize "%Folder%"
)> "%Log%"
For /f "delims=" %%a in ('Dir "%Folder%" /AD /b /s') do ( 
    (
        echo The size of "%%a" is 
        Call :GetSize "%%a"
    )>> "%Log%"
)
::start "" "%Log%"
::***********************************************************************
:GetSize
(
echo wscript.echo GetSize("%~1"^)
echo Function GetSize(MyFolder^)
echo    Set fso = CreateObject("Scripting.FileSystemObject"^)
echo    Set objFolder= fso.GetFolder(MyFolder^)  
echo    GetSize = FormatSize(objFolder.Size^)
echo End Function
echo '*******************************************************************
echo 'Function to format a number into typical size scales
echo Function FormatSize(iSize^)
echo    aLabel = Array("bytes", "KB", "MB", "GB", "TB"^)
echo    For i = 0 to 4
echo        If iSize ^> 1024 Then
echo            iSize = iSize / 1024
echo        Else
echo            Exit For
echo        End If
echo    Next
echo    FormatSize = Round(iSize,2^) ^& " " ^& aLabel(i^)
echo End Function
echo '*******************************************************************
)>%tmp%\Size.vbs
Cscript /NoLogo %tmp%\Size.vbs
Del %tmp%\Size.vbs
Exit /b
::***********************************************************************