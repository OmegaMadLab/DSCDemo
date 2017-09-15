<#
.SYNOPSIS 
Requests a certificate from a Windows CA

.DESCRIPTION
Requests a certificates with the specified subject name from am Windows CA and saves the resulting certificate with the private key in the local computer store.

You must specify at least the CN for the subject name.

With the SAN parameter you can also specify values for subject alternative name to request a SAN certificate.
The CA must support this type of certificate otherwise the request will fail.

With the Export paramter it's also posible to export the requested certificate (with private key) directly to a .pfx file instead of storing it in the local computer store.

You can also use the Import-CSV cmdlet with Request-Certificate.ps1 to request multiple certificates. 
To do this, use the Import-CSV cmdlet to create custom objects from a comma-separated value (CSV) file that contains a list of object properties (such as CN, SAN etc. ). Then pass these objects through the pipeline to Request-Certificate.ps1 to request the certificates.
    
.PARAMETER CN
Specifies the common name for the subject of the certificate(s).
Mostly its the FQDN of a website or service.
e.g. test.jofe.ch

.PARAMETER SAN
Specifies a comma separated list of subject alternate names (FQDNs) for the certificate
The synatax is {tag}={value}.
Valid tags are: email, upn, dns, guid, url, ipaddress, oid 
e.g. dns=test.jofe.ch,email=jfeller@jofe.ch

.PARAMETER TemplateName
Specifies the name for the temple of the CA to issue the certificate(s). 
The default value is "WebServer".

.PARAMETER CAName
Specifies the name of the CA to send the request to. 
If the CAName is not specified the user becomes a prompt to choose a enterprise CA from the local Active Directory.

.PARAMETER Export
Exports the certificate and private key to a pfx file insted of installing it in the local computer store.
By default the certificate will be instlled in the local computer store.

.PARAMETER Country
Specifies two letter for the optional country value in the subject of the certificate(s).
e.g. CH

.PARAMETER State
Specifies the optional state value in the subject of the certificate(s).
e.g. Berne

.PARAMETER City
Specifies the optional city value in the subject of the certificate(s).
e.g. Berne

.PARAMETER Organisation
Specifies the optional organisation value in the subject of the certificate(s).
e.g. jofe.ch

.PARAMETER Department
Specifies the optional department value in the subject of the certificate(s).
e.g. IT

.INPUTS
System.String
Common name for the subject, SAN , Country, State etc. of the certificate(s) as a string 

.OUTPUTS
None. Request-Certificate.ps1 does not generate any output.

.EXAMPLE
C:\PS> .\Request-Certificate.ps1

Description
-----------
This command requests a certificate form the enterprise CA in the local Active Directory.
The user will be asked for the value for the CN of the certificate.

.EXAMPLE
C:\PS> .\Request-Certificate.ps1 -CAName "testsrv.test.ch\Test CA"

Description
-----------
This command requests a certificate form the CA testsrv.test.ch\Test CA.
The user will be asked for the value for the CN of the certificate.

.EXAMPLE
C:\PS> .\Request-Certificate.ps1 -CN "webserver.test.ch" -CAName "testsrv.test.ch\Test CA" -TemplateName "Webservercert"
 
Description
-----------
This command requests a certificate form the CA testsrv.test.ch\Test CA with the certificate template "Webservercert"
and a CN of webserver.test.ch
The user will be asked for the value for the SAN of the certificate. 

 
.EXAMPLE
Get-Content .\certs.txt | .\Request-Certificate.ps1 -Export

Description
-----------
Gets common names from the file certs.txt and request for each a certificate. 
Each certificate will then be saved withe the private key in a .pfx file.

.EXAMPLE
C:\PS> .\Request-Certificate.ps1 -CN "webserver.test.ch" -SAN "DNS=webserver.test.ch,DNS=srvweb.test.local"
 
Description
-----------
This command requests a certificate with a CN of webserver.test.ch and subject alternative names (SANs)
The SANs of the certificate are the DNS names webserver.test.ch and srvweb.test.local.

.EXAMPLE
C:\PS> Import-Csv .\sancertificates.csv -UseCulture | .\Request-Certificate.ps1 -verbose -Export -CAName "srvca01\J0F3's Issuing CA"
 
Description
-----------
This expample requests multiple SAN certificates from the "J0F3's Issuing CA" CA running on the server "srvca01".
The first command creates custom objects from a comma-separated value (CSV) file thats conaints a list of object properties. The objects are then passed through the pipeline to Request-Certificate.ps1 to request the certificates form the "J0F3's Issuing CA" CA.
Each certificate will then be saved with the private key in a .pfx file.

The CSV file look something like this:
CN;SAN
test1.test.ch;DNS=test1san1.test.ch,DNS=test1san2.test.ch
test2.test.ch;DNS=test2san1.test.ch,DNS=test2san2.test.ch
test3.test.ch;DNS=test3san1.test.ch,DNS=test3san2.test.ch
		   
.NOTES
Version    : 1.2, 05/22/2014 (improvements for Windows Server 2012 R2)
File Name  : Request-Certificate.ps1
Requires   : PowerShell V2 

.LINK
© Jonas Feller c/o J0F3, May 2011
www.jofe.ch

#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]$CN,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string[]]$SAN,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [String]$TemplateName = "WebServer",
    [Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$CAName,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
    [switch]$Export,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$Country,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$State,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$City,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$Organisation,
	[Parameter(Mandatory=$False,ValueFromPipelineByPropertyName=$True)]
	[string]$Department
)
BEGIN {
	#internal function to do some cleanup
	function Remove-ReqTempfiles()
	{
		param(
			[String[]]$tempfiles
		)
		Write-Verbose "Cleanup temp files and pending requests"
	    
		#delete pending request (if a request exists for the CN)
		$certstore = new-object system.security.cryptography.x509certificates.x509Store('REQUEST', 'LocalMachine')
		$certstore.Open('ReadWrite')
		foreach($certreq in $($certstore.Certificates))
		{
			if($certreq.Subject -eq "CN=$CN")
			{
				$certstore.Remove($certreq)
			}
		}
		$certstore.close()
		
		foreach($file in $tempfiles){remove-item ".\$file" -ErrorAction silentlycontinue}
	}
}

PROCESS {
	#disable debug confirmation messages
	if($PSBoundParameters['Debug']){$DebugPreference = "Continue"}
	
	#check if SAN certificate is requested
	if($SAN)
	{
		#each SAN must be a array element
		#if the array has ony one element then split it on the commas.
		if(($SAN).count -eq 1)
		{
			$SAN = $SAN -split ","
			#formating $SAN to correct format
			$SAN = $SAN -join "&"
		
			Write-Host "Requesting SAN certificate with subject $CN and SAN: $SAN" -ForegroundColor Green
			Write-Debug "Parameter values: CN = $CN, TemplateName = $TemplateName, CAName = $CAName, SAN = $SAN"
		}	
	}
	else
	{
		Write-Host "Requesting certificate with subject $CN" -ForegroundColor Green
		Write-Debug "Parameter values: CN = $CN, TemplateName = $TemplateName, CAName = $CAName"
	}
	
	
	Write-Verbose "Generating request inf file"
	$file = @"
[NewRequest]
Subject = "CN=$CN,c=$Country, s=$State, l=$City, o=$Organisation, ou=$Department"
MachineKeySet = TRUE
KeyLength = 2048
KeySpec=1
Exportable = TRUE
RequestType = PKCS10
[RequestAttributes]
CertificateTemplate = "$TemplateName"
"@		

	
	#be sure that no of the tempfile exists already
	Remove-ReqTempfiles -tempfiles "certreq.inf","certreq.req","$CN.cer","$CN.rsp"
	#create new request inf file
	Set-Content .\certreq.inf $file

	#show inf file if -verbose is used
	Get-Content .\certreq.inf | Write-Verbose

	try	{
		Write-Verbose "generate .req file with certreq.exe"
		Invoke-Expression -Command "certreq -new certreq.inf certreq.req"
		if(!($LastExitCode -eq 0))
		{
		    throw "certreq -new command failed"
		}

		write-verbose "sending certificate request to CA"
		Write-Verbose "A value for the SAN is specified. Requesting a SAN certificate." 
		Write-Debug "CAName = $CAName"
		if($SAN)
		{
			Write-Debug "certreq -attrib `"SAN:$SAN`" -submit -config `"$CAName`" certreq.req $CN.cer"
			if($CAName)
			{
				Invoke-Expression -Command "certreq  -attrib `"SAN:$SAN`" -submit -config `"$CAName`" certreq.req $CN.cer"
			}
			else
			{
				Invoke-Expression -Command "certreq  -attrib `"SAN:$SAN`" -submit certreq.req $CN.cer"	
			}
		}
		else
		{
			Write-Debug "certreq -submit -config `"$CAName`" certreq.req $CN.cer"
			if($CAName)
			{
				Invoke-Expression -Command "certreq -submit -config `"$CAName`" certreq.req $CN.cer"
			}
			else
			{
				Invoke-Expression -Command "certreq -submit certreq.req $CN.cer"		
			}
		}


		if(!($LastExitCode -eq 0))
		{
		    throw "certreq -submit command failed"
		}
		Write-Debug "request was successful. Result was saved to $CN.cer"

		write-verbose "retreive and install the certifice"
		Invoke-Expression -Command "certreq -accept $CN.cer"

		if(!($LastExitCode -eq 0))
		{
		    throw "certreq -accept command failed"
		}

		if(($LastExitCode -eq 0) -and ($? -eq $true))
		{
			Write-Host "Certificate request successfully finished!" -ForegroundColor Green
		    	
		}
		else
		{
			throw "Request failed with unkown error. Try with -verbose -debug parameter"
		}


		if($export)
		{
		    Write-Debug "export parameter is set. => export certificate"
		    Write-Verbose "exporting certificate and private key"
		    $cert = Get-Childitem "cert:\LocalMachine\My" | where-object {$_.Thumbprint -eq (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Get-Item "$CN.cer").FullName,"")).Thumbprint}
		    Write-Debug "Certificate found in computerstore: $cert"

		    #create a pfx export as a byte array
		    $certbytes = $cert.export([System.Security.Cryptography.X509Certificates.X509ContentType]::pfx)

		    #write pfx file
		    $certbytes | Set-Content -Encoding Byte  -Path "$CN.pfx" -ea Stop
		    Write-Host "Certificate successfully exportert to $CN.pfx !" -ForegroundColor Green
		    
		    Write-Verbose "deleting exported certificat from computer store"
		    # delete certificate from computer store
		    $certstore = new-object system.security.cryptography.x509certificates.x509Store('My', 'LocalMachine')
		    $certstore.Open('ReadWrite')
		    $certstore.Remove($cert)
		    $certstore.close() 
		    
		}
		else
		{
		    Write-Debug "export parameter is not set. => script finished"
		    Write-Host "The certificate with the subject $CN is now installed in the computer store !" -ForegroundColor Green
		}
	}
	catch {
		#show error message (non terminating error so that the rest of the piple input get processed) 
		Write-Error $_
	}
	finally {
		#tempfiles and request cleanup
		Remove-ReqTempfiles -tempfiles "certreq.inf","certreq.req","$CN.cer","$CN.rsp"
	}
}

END 
{
	Remove-ReqTempfiles -tempfiles "certreq.inf","certreq.req","$CN.cer","$CN.rsp"
}