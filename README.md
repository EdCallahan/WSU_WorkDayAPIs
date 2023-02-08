# WSU Shared WorkDay API PowerShell/SQL Code

Code to interact with WorkDay APIs via Powershell. Maintained and shared by Winona State University, but not supported by us. 

Currently, the code is designed to explore the organizational structure and worker assignements in WorkDay, with the hopes of
being able to compaire that to the Org Maint tables in ISRS.

Ed Callahan  
Winona State University  
2/6/2023

---

## Modules Directory

- **Write-SecretKeys** / **Read-SecretKeys** - Functions to store auth tokens (username, password, OAuth2 tokens, etc) encrypted in a file
- **Format-XML** - Utility to convert an XML object to a nicely formatted string
- **Get-WebRequestError** - Utiltiy function to handle web request error messages differently for Windows PowerShell 5.2 and PowerShell 6/7
- **Invoke-WorkdayRequest** - Makes an API call with OAuth2 credentials and returns a page of results. Since WorkDay returns results a page at a time instead of all records at once, this function often needs to be called in a loop (once for each page of resutls)

## 01 Retrieve WD HR Data.ps1

Contains a basic Get_Workers_Request request as SOAP XML and retrieves all pages of results, writing them to a XML file on disk.

## 02 Import HR Org Data to SQL.sql

SQL to pull the XML file into a staging SQL table, then processes it to extract organizational data for each worker.

The PowerShell script could write directly to the SQL database without needing to stage the data in a file first. But this method is more platform agnostic so I'm leaving it this way for the purpose of sharing code.

