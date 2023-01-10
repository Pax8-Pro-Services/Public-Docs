echo off
::echo on
Title Pax8 File Share Discovery -- LONG File Paths
::==================================================================================
:: LIST ALL FILE PATHS THAT EXCEED 255 CHARACTERS
:: A script to list all file paths exceeding 255 characters in a directory. 
::  Description:
::   - Creates a temp directory for file output called 'C:\TempPax8'
::   - Promptes for local file share path
::   - Exports contents to C:\TempPax8\get_LongFilePaths.txt
::
:: Revised: 6/6/2021
::==================================================================================

echo ==================================================================================
echo  LIST ALL FILE PATHS THAT EXCEED 255 CHARACTERS
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
@Echo off
Setlocal EnableDelayedExpansion
:: Report all file / folder paths that exceed the 256 character limit
::If {%1}=={} Echo Syntax: XLong DriveLetter&goto :EOF
::Set wrk=%1
::Set wrk=%wrk:"=%

For /F "Tokens=*" %%a in ('dir %ShareData% /b /s /a') do (
 set name=%%a
:: if not "!name:~255,1!"=="" echo Extra long name: "%%a"
if not "!name:~255,1!"==""  ( echo >> C:\TempPax8\get_LongFilePaths.txt )
)
Endlocal