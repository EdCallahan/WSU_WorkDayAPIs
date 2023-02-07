<#
.SYNOPSIS
Get a hash of authentication keys from file

.DESCRIPTION
Get a hash of authentication keys (username, password, OAuth2 keys, etc) from file written by Write-SecretKeys

.PARAMETER FileName
Name of the file with encrypted authentication keys

.EXAMPLE
Read-SecretKeys -File "$HOME\WDAuthKeys.txt"
#>
function Read-SecretKeys
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$FileName
    )

    $keys = @{}

    $null = Get-Content $FileName |
        ForEach-Object{ $c = $_ -split ','; $keys[$c[0]] = $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'N/A', (ConvertTo-SecureString $c[1])).GetNetworkCredential().Password }

    $keys

}