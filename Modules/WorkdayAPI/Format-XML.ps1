<#
.SYNOPSIS
Convert XML to a nicely formatted string

.DESCRIPTION
Convert XML to a nicely formatted string.

.PARAMETER XML
XMLDocument object to format

.PARAMETER Indent
Number of spaces to use when indenting XML blocks

.EXAMPLE
$xml | Format-XML
#>
function Format-XML {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [xml]$XML,

        [parameter(Mandatory = $false, Position = 1)]
        [int]$Indent = 2
    )
    Begin {

        $StringWriter = New-Object System.IO.StringWriter
        $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
        $xmlWriter.Formatting = 'indented'
        $xmlWriter.Indentation = $Indent

    }
    Process {

        $XML.WriteContentTo($XmlWriter)
        $XmlWriter.Flush()
        $StringWriter.Flush()
        $StringWriter.ToString()

    }
    End {

        $XmlWriter = $null
        $StringWriter = $null

    }
}