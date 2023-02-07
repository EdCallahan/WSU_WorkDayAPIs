<#

Retrieve WorkDay data via SOAP APIs and OAuth2 authentication

Based Nathan Hartley’s work at https://github.com/treestryder/powershell_module_workdayapi
and Jeremy Heydman's groovy code and advice

This pulls HR Data, but should work with other APIs with the right SOAP request:

Get-Workers API documentation:
https://community.workday.com/sites/default/files/file-hosting/productionapi/Human_Resources/v39.2/Get_Workers.html

Kitchen sink SOAP example:
https://community.workday.com/sites/default/files/file-hosting/productionapi/Human_Resources/v39.0/samples/Get_Workers_Request.xml

Other APIs:
https://community.workday.com/sites/default/files/file-hosting/productionapi/operations/index.html


Ed Callahan, Winona State University, 1/28/2023

#>


##
## Config and Params
##

if ( ($env:PSModulePath -split ';') -notcontains "${PSScriptRoot}\Modules" -and (Test-Path "${PSScriptRoot}\Modules") ) { $env:PSModulePath += ";${PSScriptRoot}\Modules" }

# If this fails, you'll need to adjust your $env:PSModulePath value to include the Modules subdirectory under where this file is found
Import-Module WorkdayAPI -Force


###
### Parameters
###

# To store credentials securely, you can run this code:
<#
    $AuthKeys = @{
        tenant = 'minnstate4'
        oauth2_client_id = ''
        oauth2_refresh_token = ''
        oauth2_client_secret = ''
    }

    Write-SecretKeys -FileName "$HOME/WDAuthKeys.txt"  -Keys $AuthKeys
#>

$AuthKeys = Read-SecretKeys -FileName "$HOME/WDAuthKeys.txt"

# the ID of your campus (company in WorkDay parlance)
$campus_id = 'CU0074'

# file to output the XML result to
$fn = 'c:\temp\WD_Workers_{0}.xml' -f (Get-Date).ToString("yyyyMMdd_hhmmss")


###
### Main Program
###

#
# The basic form of the SOAP request, although it needs to be wrapped in an authentication envelope before submitting
#
# See https://community.workday.com/sites/default/files/file-hosting/productionapi/Human_Resources/v39.2/Get_Workers.html
#

$request = [xml]'
<bsvc:Get_Workers_Request bsvc:version="v39.0" xmlns:bsvc="urn:com.workday/bsvc">
    <bsvc:Response_Filter>
        <bsvc:Page></bsvc:Page>
        <bsvc:As_Of_Entry_DateTime></bsvc:As_Of_Entry_DateTime>
    </bsvc:Response_Filter>
    <bsvc:Request_Criteria>
        <bsvc:Exclude_Inactive_Workers>true</bsvc:Exclude_Inactive_Workers>
        <bsvc:Organization_Reference>
            <bsvc:ID bsvc:type="Company_Reference_ID">XX</bsvc:ID>
        </bsvc:Organization_Reference>
        <bsvc:Include_Subordinate_Organizations>true</bsvc:Include_Subordinate_Organizations>
    </bsvc:Request_Criteria>
    <bsvc:Response_Group>
        <bsvc:Include_Reference>true</bsvc:Include_Reference>
        <bsvc:Include_Personal_Information>false</bsvc:Include_Personal_Information>
        <bsvc:Include_Employment_Information>false</bsvc:Include_Employment_Information>
        <bsvc:Include_Compensation>false</bsvc:Include_Compensation>
        <bsvc:Include_Organizations>false</bsvc:Include_Organizations>
        <bsvc:Include_Roles>false</bsvc:Include_Roles>
        <bsvc:Include_Worker_Documents>false</bsvc:Include_Worker_Documents>
        <bsvc:Include_User_Account>true</bsvc:Include_User_Account>
    </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
'

# trim results to only your campus (Company in Workday parlance)
# although this should be enforced automatically if WorkDay and your account are configured correctly
# CU0074 = Winona
$request.Get_Workers_Request.Request_Criteria.Organization_Reference.ID.'#text' = $campus_id

# set the As Of timestamp for the request
$request.Get_Workers_Request.Response_Filter.As_Of_Entry_DateTime = (Get-Date).ToString('o')

# Returning organiation data takes seome time and creates a large XML text file
$request.Get_Workers_Request.Response_Group.Include_Organizations = 'true'


##
## Collect each page of data from Workday
##
## WorkDay returns the result set in chunks (pages), we iterate through them until we have it all
##

# list of workers the following loop will populate
# Using ArrayList because += on native arrays is pretty slow
$workers = [System.Collections.ArrayList]@()

# iterate through each page of data
$more = $true; $nextPage = 0
while ($more) {

    Write-Host $nextPage

    # set which page of data to retrieve
    $nextPage += 1
    $request.Get_Workers_Request.Response_Filter.Page = $nextPage.ToString()

    # get a page of data from Workday. Credentidas are handled within the Invoke-WorkdayRequst function
    $response = Invoke-WorkdayRequest -Request $request -AuthKeys $AuthKeys

    # add this XML block of data onto the $workers array we're populating
    $null = $workers.AddRange($response.Xml.Get_Workers_Response.Response_Data.Worker)

    # append this block of data to the XML file we're building
    $null = $response.Xml.Get_Workers_Response.Response_Data.Worker | ForEach-Object {
        $x = [xml]''
        $n = $x.ImportNode($_, $true)
        $x.AppendChild($n)
        $x | Format-XML | Out-File $fn -Append
    }

    # check if there is more data to retrieve
    $more = $response.Success -and $nextPage -lt $response.xml.Get_Workers_Response.Response_Results.Total_Pages

}

##
## Complete. Now you can work the the results from the XML file of the $workers array
##
