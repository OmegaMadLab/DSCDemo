Set-Location $basePath\$unifiedConfigModulePath

start-process iexplore.exe file://$basePath/$unifiedConfigModulePath/demo06.jpg

#### Preparing environment for encryption certificates generated by ADCS

. .\helperScripts
#ise .\helperScripts.ps1

# Generating certificate template
$templateName = "DscEncryptionTemplate"
createDscCertTemplate -templateName $templateName

# Enabling template on CA
Invoke-command -ComputerName $DC {Add-CATemplate -name $using:templateName -force}

# Move all computer account in a dedicated OU, with an autoenrollment GPO linked on it
# ise .\generateAndDeployDscCerts.ps1
Invoke-command -ComputerName $DC -FilePath .\generateAndDeployDscCerts.ps1


#### Changing LCM config on target nodes
ise .\pullClientConfig_v2.ps1

Install-Module PKITools
Get-Command -Module PKITools

# Get OID from DSC template
$dscOid = Get-CertificateTemplateOID -Name $templateName

# Get all certs issued with the above OID
$certs = Get-IssuedCertificate -CertificateTemplateOid $dscOid -Properties 'Issued Common Name', 'Binary Certificate'

# Saving certs in C:\Certificates
if(!(Test-Path "C:\Certificates"))
{
    $certFolder = New-Item -Path C:\Certificates -ItemType Directory
}

foreach ($cert in $certs) {
    Set-Content -Path "C:\Certificates\$($cert.'Issued Common Name').cer" -Value $cert.'Binary Certificate' -encoding ASCII
}

Start-Process explorer.exe C:\Certificates

# Defining computers affected by the LCM configuration change
$targetNodes = $FE01, $FE02, $BE01, $BE02, $DEVENV

# loading LCM configuration
. .\pullClientConfig_v2.ps1

# compiling config data hash table at runtime
foreach ($targetNode in $targetNodes) {

    # Gettting cert with relative thumbprint from disk    
    $certPath = "C:\Certificates\$targetNode.cer"
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($certPath)

    # Append a child node to hash table
    $configData.AllNodes += @{
        NodeName = $targetNode
        Thumbprint = $cert.Thumbprint
    }

}

$configData.AllNodes

pullClientConfig_v2 -ConfigurationData $configData

# Pushing LCM config
Set-DscLocalConfigurationManager .\pullClientConfig_v2 -Force -Verbose


#### Preparing the unified configuration
ise .\unifiedConfig.ps1

# Preparing DNS records for websites
$scriptBlock = {
    $dnsZone = Add-DnsServerPrimaryZone -Name "sidit17.demo" -ReplicationScope "Forest" -PassThru
    Add-DnsServerResourceRecord -A -Name "frontendwebsite-test" -IPv4Address $using:devEnvIp -zoneName $dnsZone.zoneName
    Add-DnsServerResourceRecord -A -Name "backendwebsite-test" -IPv4Address $using:devEnvIp -zoneName $dnsZone.zoneName
    Add-DnsServerResourceRecord -A -Name "frontendwebsite" -IPv4Address $using:FE01ip -zoneName $dnsZone.zoneName
    Add-DnsServerResourceRecord -A -Name "frontendwebsite" -IPv4Address $using:FE02ip -zoneName $dnsZone.zoneName
    Add-DnsServerResourceRecord -A -Name "backendwebsite" -IPv4Address $using:BE01ip -zoneName $dnsZone.zoneName
    Add-DnsServerResourceRecord -A -Name "backendwebsite" -IPv4Address $using:BE02ip -zoneName $dnsZone.zoneName
}
Invoke-command -ComputerName $DC -scriptBlock $scriptBlock

# Requesting SSL cert for production
.\Request-Certificate.ps1 -CN "webserver-ssl" `
                          -SAN "DNS=frontendwebsite.sidit17.demo,DNS=backendwebsite.sidit17.demo" `
                          -CAName "$DC\SIDIT17-Root-CA"
$pfxPwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
$sslCert = Get-ChildItem -Path Cert:\LocalMachine\My -SSLServerAuthentication | ? {$_.Subject -like '*webserver*'} 
$sslCert | Export-PfxCertificate -FilePath C:\SourceShare\sslcert.pfx -Password $pfxPwd

# list of modules that need to be installed and packed
$dscModules = 'xWebAdministration', 'xCertificate'

$dscModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"

# Get modules and create a zip [moduleName]_[Version].zip naming convention inside DSC Pull server module repository
# As an alternative, you can use functions from PublishModulesAndMofsToPullServer.psm1, which is bundled with xPsDesiredStateConfiguration
# https://github.com/PowerShell/xPSDesiredStateConfiguration/tree/dev/DSCPullServerSetup
getAndZipModule -dscModuleNames $dscModules -dscPullSrvModulePath $dscModulePath

Start-process explorer.exe $dscModulePath

. .\unifiedConfig.ps1


# compiling config data hash table at runtime
foreach ($targetNode in $targetNodes) {

    # Gettting cert with relative thumbprint from disk    
    $certPath = "C:\Certificates\$targetNode.cer"
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($certPath)

    ($configData.AllNodes | ? {$_.nodeName -eq $targetNode}).Thumbprint = $cert.Thumbprint
    ($configData.AllNodes | ? {$_.nodeName -eq $targetNode}).CertificateFile = $certPath

}

$pfxCertPath = "\\$DSC\SourceShare\sslCert.pfx"
#$pfxCert = Get-pfxCertificate -FilePath $pfxCertPath
$pfxCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfxCert.Import($pfxCertPath,'1234','DefaultKeySet')

($configData.AllNodes | ? {$_.nodeName -eq "*"}).PfxThumbprint = $pfxCert.Thumbprint
($configData.AllNodes | ? {$_.nodeName -eq "*"}).PfxPath = $pfxCertPath

$secpasswd = ConvertTo-SecureString '1234' -AsPlainText -Force
$pfxCreds = New-Object System.Management.Automation.PSCredential ('fakeUserNotBeingUsed', $secpasswd)

# Generating configuration and checksum
unifiedConfig -ConfigurationData $configData -pfxCreds $pfxCreds -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
New-DscChecksum -path "C:\Program Files\WindowsPowerShell\DscService\Configuration\*" -Force

Start-process explorer.exe "C:\Program Files\WindowsPowerShell\DscService\Configuration"

# Forcing update on DEVENV
Update-DscConfiguration -ComputerName $DEVENV -Wait -Verbose
# Check
Start-Process iexplore.exe "http://frontendwebsite-test.sidit17.demo/app"

# Forcing update on PROD
Update-DscConfiguration -ComputerName $FE01 -Wait -Verbose
Update-DscConfiguration -ComputerName $FE02 -Wait -Verbose
Update-DscConfiguration -ComputerName $BE01 -Wait -Verbose
Update-DscConfiguration -ComputerName $BE02 -Wait -Verbose
# Check
Start-Process iexplore.exe "https://frontendwebsite.sidit17.demo/app"


#### Looking at DSC Reports on Pull Server
#### Adapted from https://msdn.microsoft.com/en-us/powershell/dsc/reportserver

# Getting agent ID from target node
$agentId = (Get-DSCLocalConfigurationManager -CimSession $FE01).AgentId

$pullServerUrl = "https://dscpullserver.$domainName/PSDSCPullServer.svc" 

# Important! With UseSecurityBestPractices = $true, Pull Server won't work with invoke-webrequest which uses TLS 1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Invoking report server
$requestUri = "$pullServerUrl/Nodes(AgentId='$AgentId')/Reports"
$request = Invoke-WebRequest -Uri $requestUri `
                             -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" `
                             -UseBasicParsing `
                             -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} `
                             -ErrorAction SilentlyContinue `
                             -ErrorVariable ev
$Reports = (ConvertFrom-Json $request.content).value

$Reports

$Reports[0]

$Reports[0].StatusData | ConvertFrom-Json

