foreach ($f in Get-ChildItem "$PSScriptRoot\\*" -Include '*.ps1')
{
    . $f.FullName
}