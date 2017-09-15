Set-Location $basePath\$initialConfigModulePath

Get-DSCResource -Module PSDesiredStateConfiguration

Get-DscResource File -Syntax

Find-Module x*
Find-Module c*

Install-Module xWebAdministration

ise .\empty.ps1

Get-DscLocalConfigurationManager


#### Simple web site
start-process iexplore.exe file://$basePath/$initialConfigModulePath/demo01.jpg

ise .\simpleWebSiteTest.ps1

# Configuration load and compilation
. .\simpleWebSiteTest.ps1
simpleWebSiteTest

ise .\simpleWebsiteTest\$fe01.mof

# Applying configuration (PUSH mode)
Start-DscConfiguration .\simpleWebSiteTest -Wait -Force -Verbose

# Check
start-process iexplore.exe "http://$FE01/index.htm"

# Server not joined to domain
ise .\simpleWebSiteTest_ndj.ps1

# Configuration load and compilation
. .\simpleWebSiteTest_ndj.ps1
simpleWebsiteTest_ndj

# Applying configuration (PUSH mode)
Start-DscConfiguration .\simpleWebsiteTest_ndj -Wait -Force -Verbose

# Adding entry on hosts file
$hosts = "$env:windir\system32\drivers\etc\hosts"
$NDJSRV.ip + " " + $NDJSRV.name | Add-Content -PassThru $hosts

# Adding server in the WinRM TrustedHosts list
WINRM set winrm/config/client "@{TrustedHosts=`"$($NDJSRV.name)`"}"

# Applying configuration (PUSH mode) passing remote server credential
Start-DscConfiguration .\simpleWebSiteTest_ndj -Wait -Force -Verbose -Credential (Get-Credential) 

# Check
start-process iexplore.exe "http://$($NDJSRV.name)/index.htm"

#### Troubleshoot DSC
Get-DscConfigurationStatus -CimSession $fe01
$dscStatus = Get-DscConfigurationStatus -CimSession $fe01
$dscStatus | select *
$dscStatus.ResourcesInDesiredState

# From https://msdn.microsoft.com/it-it/powershell/dsc/troubleshooting
<##########################################################################
 Step 1 : Enable analytic and debug DSC channels (Operational channel is enabled by default)
###########################################################################>

wevtutil.exe set-log “Microsoft-Windows-Dsc/Analytic” /q:true /e:true
wevtutil.exe set-log “Microsoft-Windows-Dsc/Debug” /q:True /e:true

<##########################################################################
 Step 2 : Perform the required DSC operation (Below is an example, you could run any DSC operation instead)
###########################################################################>

. .\testTroubleshooting.ps1
testTroubleshooting

Start-DscConfiguration .\testTroubleshooting -Wait -Force -Verbose

<##########################################################################
Step 3 : Collect all DSC Logs, from the Analytic, Debug and Operational channels
###########################################################################>

$DscEvents=[System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Operational") `
         + [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Analytic" -Oldest) `
         + [System.Array](Get-WinEvent "Microsoft-Windows-Dsc/Debug" -Oldest)


<##########################################################################
 Step 4 : Group all logs based on the job ID
###########################################################################>
$SeparateDscOperations = $DscEvents | Group {$_.Properties[0].value}


# Log entries for last 5 minutes
$SeparateDscOperations | ? {$_.Group.TimeCreated -gt (Get-Date).AddMinutes(-5)}

# Log entries for latest operation
$SeparateDscOperations[0].Group.Message

#### xDSCDiagnostics module
Install-Module xDscDiagnostics

Get-Command -Module xDscDiagnostics

Get-xDscOperation

$dscTrace = Trace-xDscOperation -SequenceID 1

$dscTrace.event