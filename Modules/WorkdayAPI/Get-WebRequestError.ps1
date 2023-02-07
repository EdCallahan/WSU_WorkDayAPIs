<#
.SYNOPSIS
Extract error message from the exceptions thrown by web calls

.DESCRIPTION
Extract error message from the exceptions thrown by web calls. Abstracted to a function because the method
differs between Windows Powersehll 5.2 and Powershell 6 and later.


.PARAMETER Error
Error thrown by Invoke-RestMethod, etc

.OUTPUTS
Error message string

.EXAMPLE
try {
    $result = Invoke-RestMethod -Uri $auth_url -Method Post -Body $req
}
catch {

    $msg = $_.Exception.Message
    $response_msg = Get-WebRequestError $_

    throw ("Error with {0}: {1}`n{2}"" -f $auth_url, $msg, $response_msg)
}
#>
function Get-WebRequestError {

    [CmdletBinding()]
    param
    (
        [parameter(Position = 0, Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$Error
    )

    if ($PSVersionTable.PSVersion.Major -lt 6) {

        # Windows Powershell method

        try {
            $strm = $Error.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($strm)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $response_msg = $reader.ReadToEnd()
        }
        catch {
            $response_msg = ''
        }

    }
    else {

        # Powershell method

        $response_msg = $Error.ErrorDetails.Message
    }

    return $response_msg

}