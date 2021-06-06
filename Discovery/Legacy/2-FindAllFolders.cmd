echo off
::echo on
Title Pax8 File Share Discovery -- File All Folders
::==================================================================================
:: LIST ALL FOLDERS AND SUBFOLDERS IN A DIRECTORY
:: A script to list all FOLDERS and SUBFOLDERS in a directory. 
::  Description:
::   - Creates a temp directory for file output called 'C:\TempPax8'
::   - Promptes for local file share path
::   - Exports contents to C:\TempPax8\get_AllFolders.txt
::
:: Revised: 6/6/2021
::==================================================================================

echo ==================================================================================
echo  LIST ALL FOLDERS AND SUBFOLDERS IN A DIRECTORY
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
for /r %%a in (*) do echo %%a >> C:\TempPax8\get_AllFolders.txt