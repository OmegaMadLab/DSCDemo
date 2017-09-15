gpupdate /force /target:Computer

Set-Location $basePath\$pullServerModulePath

start-process iexplore.exe file://$basePath/$pullServerModulePath/demo04.jpg

# Installing required DSC resource
Install-Module xPSDesiredStateConfiguration -Force

#### HTTP Pull Server
ise .\unsecurePullServer.ps1

#### HTTPS Pull Server
ise .\sslPullServer.ps1

# Creating a CNAME record for PULL Server
$scriptBlock = {
    Add-DnsServerResourceRecordCName -Name 'dscpullserver' `
                                        -HostNameAlias "$using:DSC" `
                                        -zoneName "$using:domainName"
}
Invoke-command -ComputerName $DC -scriptBlock $scriptBlock

# Get an SSL certificate for the website
# https://gallery.technet.microsoft.com/scriptcenter/Request-certificates-from-b6a07151
.\Request-Certificate.ps1 -CN "dscpullserver.$domainName" -CAName "$DC\SIDIT17-Root-Ca"

# Get certificate thumbprint
$cert = (Get-ChildItem -Path Cert:\LocalMachine\My | ?{$_.Subject -like "CN=dscpullserver*"})
$cert

# Get a new GUID to be used as registration key
$regKey = (New-Guid).Guid
$regKey

# Applying configuration to the pull server
. .\sslPullServer.ps1
sslPullServer -certThumbPrint $cert.Thumbprint -regkey $regKey

Start-DscConfiguration .\sslPullServer -Wait -Force -Verbose 

# Checking web service status
start-process iexplore.exe "https://dscpullserver.$domainName/PSDSCPullServer.svc"


