<#
.SYNOPSIS
Write a file of encrypted authentication keys

.DESCRIPTION
Write a hash of authentication keys (username, password, OAuth2 keys, etc) to a file, to be read by Read-SecretKeys

.PARAMETER FileName
Name of the file to hold encrypted authentication keys

.PARAMETER Keys
Hash of authentication keys (username, password, OAuth2 keys, etc)

.EXAMPLE
$keys = @{username='Ed'; password='r6&Ade%B'}
Write-SecretKeys -File "$HOME\WDAuthKeys.txt" -Keys $keys
#>
function Write-SecretKeys
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FileName,
        [Parameter(Mandatory=$true, Position=1)]
        [HashTable]$Keys
    )

    $null = $Keys.GetEnumerator() |
        Where-Object { $_.Value -ne '' } |
        ForEach-Object {($_.Key, (ConvertTo-SecureString -String $_.Value -AsPlainText -Force | ConvertFrom-SecureString)) -join ','} |
        Out-File -FilePath $FileName

}
