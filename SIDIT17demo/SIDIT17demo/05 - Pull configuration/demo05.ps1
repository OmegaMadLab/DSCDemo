Set-Location $basePath\$pullConfigModulePath

start-process iexplore.exe file://$basePath/$pullConfigModulePath/demo05.jpg

#### target node LCM config for PULL
ise .\pullClientConfig.ps1

# Get registration key for target nodes
$regKey = Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'

# Generating LCM config and applying it to FE01 and FE02
. .\pullClientConfig.ps1
pullClientConfig -computerName $FE01, $FE02 `
                    -regKey $regKey `
                    -pullUrl "https://dscpullserver.$domainName/PSDSCPullServer.svc" `
                    -configName 'loadBalancedWebSiteConfig'

Set-DscLocalConfigurationManager -Path .\pullClientConfig -ComputerName $FE01, $FE02 -Verbose

#### website configuration (PULL mode)
ise .\loadBalancedWebSite.ps1

# Get a DNS record for load balanced website
$scriptBlock = {
    Add-DnsServerResourceRecord -CName
                                -HostNameAlias "loadBalancedWebSite" 
                                -Name $using:FE01
                                -zoneName $using:domainName
    Add-DnsServerResourceRecord -CName
                                -HostNameAlias "loadBalancedWebSite" 
                                -Name $using:FE02
                                -zoneName $using:domainName
}
Invoke-command -ComputerName $DC -scriptBlock $scriptBlock

. .\helperScripts.ps1
ise .\helperScripts.ps1

# list of modules that need to be installed and packed
$dscModuleNames = 'xNetworking', 'xWebAdministration'

# Get modules and create a zip [moduleName]_[Version].zip naming convention inside DSC Pull server module repository
# As an alternative, you can use functions from PublishModulesAndMofsToPullServer.psm1, which is bundled with xPsDesiredStateConfiguration
# https://github.com/PowerShell/xPSDesiredStateConfiguration/tree/dev/DSCPullServerSetup
getAndZipModule -dscModuleNames $dscPullSrvModuleNames -dscModulePath "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"

Start-Process explorer.exe 'C:\Program Files\WindowsPowerShell\DscService\Modules'

# Compiling configuration in the DSC Service Configuration path
. .\loadBalancedWebSite.ps1
$mofFile = loadBalancedWebSite -sourceFolder "\\$($DSC)\SourceShare\loadBalancedWebSite" `
                                -hostHeader 'loadBalancedWebSite' `
                                -OutputPath 'C:\Program Files\WindowsPowerShell\DscService\Configuration'

# Generating checksum for config file
New-DscChecksum $mofFile.FullName -Force

# Trigger target node update
Update-DscConfiguration -ComputerName $FE01, $FE02 -Wait -Verbose

# check
Start-Process iexplore.exe -ArgumentList http://loadbalancedwebsite

#### Hosts file test

# Adding an entry for localhost on FE01
$scriptBlock = {
    $hosts = "$env:windir\system32\drivers\etc\hosts"
    "127.0.0.1 loadBalancedWebSite" | Add-Content -PassThru $hosts
}
Invoke-Command -ComputerName $FE01 -ScriptBlock $scriptBlock
Invoke-Command -ComputerName $FE01 -ScriptBlock {Resolve-DnsName loadBalancedWebSite}

# Forcing configuration refresh on FE01; normally it would be applied automatically
Start-DscConfiguration -ComputerName $FE01 -UseExisting -Force -Wait -Verbose
Invoke-Command -ComputerName $FE01 -ScriptBlock {Resolve-DnsName loadBalancedWebSite}

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

