## Welcome to the Pax8 Pro Services File Share Discovery Tool

This is a GitHub Repository managed by the Pax8 Professional Services Team. If you're on this page, you probably found us by mistake.
Your Pro Servies engineer should send you a direct link to the document they need you to refer to.

PURPOSE
    Inventory the local windows based, or windows mapped, file share content in preparation for migration.
    
DESCRIPTION
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

MUST RUN SCRIPT AS ADMINISTRATOR!

![Image](https://www.pax8.com/en-us/wp-content/uploads/sites/4/cache/2020/04/pax8-logo-2-color-dark-200x200-cropped.png)
![Image](https://raw.githubusercontent.com/Pax8-Pro-Services/Public-Docs/master/Main%400.5x.png)




Powered By [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).
