<#
.SYNOPSIS
    Sends XML requests to Workday API, with proper authentication and receives XML response.

.DESCRIPTION
    Sends XML requests to Workday API, with proper authentication and receives XML response.

    Used for all communication to Workday in this module and may be used to send
    custom XML requests.

.PARAMETER Request
    The Workday request XML to be sent to Workday.
    See https://community.workday.com/custom/developer/API/index.html for more information.

.INPUTS
    Workday XML

.OUTPUTS
    Workday XML
#>

function Invoke-WorkdayRequest {

	[CmdletBinding()]
    [OutputType([XML])]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[xml]$Request,

        # hastable of credentials
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[hashtable]$AuthKeys
	)

    ##
    ## Get Credentials
    ##

    $version = 'v39.0'
    $uri = 'https://wd2-impl-services1.workday.com/ccx/service/{0}/Human_Resources/{1}' -f $AuthKeys.tenant, $version
    $token_uri = "https://wd2-impl-services1.workday.com/ccx/oauth2/{0}/token" -f $AuthKeys.tenant

    $body = "client_id={0}&client_secret={1}&grant_type=refresh_token&refresh_token={2}" -f $AuthKeys.oauth2_client_id, $AuthKeys.oauth2_client_secret, $AuthKeys.oauth2_refresh_token
    $headers = @{'Content-Type' = 'application/x-www-form-urlencoded'}

    try {
        $response = Invoke-RestMethod -Uri $token_uri -Method Post -Headers $headers -Body $body
        $token = $response.access_token
    }
    catch {
        $msg = $_.Exception.Message

        $strm = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($strm)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $response = $reader.ReadToEnd();

        throw ("Could not get token: {0}`n{1}" -f $msg, ($response | ConvertFrom-Json).Message)
    }


    ##
    ## Create SOAP request envelope with credentials, insert workday request XML into it
    ##

	$WorkdaySoapEnvelope = [xml]'
        <soapenv:Envelope xmlns:bsvc="urn:com.workday/bsvc" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
            <soapenv:Body>
                <bsvc:RequestNode xmlns:bsvc="urn:com.workday/bsvc" />
            </soapenv:Body>
        </soapenv:Envelope>
        '

	# $WorkdaySoapEnvelope.Envelope.Header.Security.UsernameToken.Username = $username
	# $WorkdaySoapEnvelope.Envelope.Header.Security.UsernameToken.Password.InnerText = $password
	$WorkdaySoapEnvelope.Envelope.Body.InnerXml = $Request.OuterXml

	Write-Debug "Request: $($WorkdaySoapEnvelope.OuterXml)"


    ##
    ## Send the request to WorkDay
    ##

    $headers= @{
		'Content-Type' = 'text/xml;charset=UTF-8'
        # 'wd-external-request-id' = requestId
        'wd-external-application-id' = 'campus-poc-example'
        'wd-external-originator-id' = $AuthKeys.username
        'Authorization' = "Bearer $token"
      }

     $o = [pscustomobject][ordered]@{
        Success    = $false
        Message  = 'Unknown Error'
        Xml = $null
    }
    $o.psobject.TypeNames.Insert(0, "WorkdayResponse")

	$response = $null

    try {
		$response = Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers -Body $WorkdaySoapEnvelope -ErrorAction Stop
        $o.Xml = [xml]$response.Envelope.Body.InnerXml
        $o.Message = ''
        $o.Success = $true
	}
	catch [System.Net.WebException] {
        Write-Debug $_
        $o.Success = $false
        $o.Message = $_.ToString()

        try {
            $reader = New-Object System.IO.StreamReader -ArgumentList $_.Exception.Response.GetResponseStream()
            $response = $reader.ReadToEnd()
            $reader.Close()
            $o.Message = $response
            $xml = [xml]$response
            $o.Xml = [xml]$xml.Envelope.Body.InnerXml

            # Put the first Workday Exception into the Message property.
            if ($o.Xml.InnerXml.StartsWith('<SOAP-ENV:Fault ')) {
                $o.Success = $false
                $o.Message = "$($o.Xml.Fault.faultcode): $($o.Xml.Fault.faultstring)"
            }
        }
        catch {}
	}
    catch {
        Write-Debug $_
        $o.Success = $false
    }
    finally {
        Write-Output $o
    }

}
