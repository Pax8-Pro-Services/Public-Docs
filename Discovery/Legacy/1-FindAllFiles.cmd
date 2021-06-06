echo off
::echo on
Title Pax8 File Share Discovery -- Find ALL Files
::==================================================================================
:: LIST ALL FILES IN A DIRECTORY AND SUBDIRECTORY
:: A script to list all files in a directory and all corresponding subdirectories. 
::  Description:
::   - Creates a temp directory for file output called 'C:\TempPax8'
::   - Promptes for local file share path
::   - Exports contents to C:\TempPax8\get_AllFiles.txt
::
:: Revised: 6/6/2021
::==================================================================================

echo ==================================================================================
echo  LIST ALL FILES IN A DIRECTORY AND SUBDIRECTORY
echo  Revised: 6/6/2021
echo 
echo ==================================================================================

:: Create Folder
md C:\TempPax8
echo Enter the local directory of the file share.
echo Ex. D:\Share or E:\Data\Share
set /p ShareData=Enter Path:  
echo Search directory is: %ShareData%
:: Change to working file share directory entered
CD /D %ShareData%
for /r %%a in (*) do echo %%a >> C:\TempPax8\get_AllFiles.txt