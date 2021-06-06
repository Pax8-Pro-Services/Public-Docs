echo off
::echo on
Title Pax8 File Share Discovery -- Find NTFS Permissions
::==================================================================================
:: LIST ALL NTFS PERMISSIONS FOR DIRECTORY AND SUBDIRECTORIES
:: A script to list all NTFS file permissions in a directory and subdirectories. 
::  Description:
::   - Creates a temp directory for file output called 'C:\TempPax8'
::   - Promptes for local file share path
::   - Exports contents to C:\TempPax8\get_NTFSPermissions.txt
::
:: Revised: 6/6/2021
::==================================================================================

echo ==================================================================================
echo  LIST ALL NTFS PERMISSIONS FOR DIRECTORY AND SUBDIRECTORIES
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
icacls %ShareData% /t /c /l /q >> C:\TempPax8\get_NTFSPermissions.txt