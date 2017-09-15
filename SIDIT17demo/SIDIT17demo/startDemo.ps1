$Global:domainName = 'sidit17.local'

$Global:DC = 'sidit17-dc.' + $Global:domainName
$Global:DSC = 'sidit17-dsc.' + $Global:domainName
$Global:FE01 = 'sidit17-fe01.' + $Global:domainName
$Global:FE02 = 'sidit17-fe02.' + $Global:domainName
$Global:BE01 = 'sidit17-be01.' + $Global:domainName
$Global:BE02 = 'sidit17-be02.' + $Global:domainName
$Global:DEVENV = 'sidit17-devenv.' + $Global:domainName

$Global:NDJSRV = @{
    name = 'sidit17-ndj'
    ip = '172.17.3.15'
}


#$Global:feIlbIp = '172.17.3.11'
#$Global:beIlbIp = '172.17.3.12'
$global:DEVENVip = '172.17.3.8'
$global:FE01ip = '172.17.3.6'
$global:FE02ip = '172.17.3.7'
$global:BE01ip = '172.17.3.9'
$global:BE02ip = '172.17.3.10'

$Global:basePath = 'C:\Users\sjadmin\Desktop\SIDIT17demo'

$Global:envPreparationPath = '.\00 - environment preparation'
$Global:initialConfigModulePath = '.\01 - initial config'
$Global:configDataParametersModulePath = '.\02 - configuration data and parameters'
$Global:securityModulePath = '.\03 - Security'
$Global:pullServerModulePath = '.\04 - Pull server'
$Global:pullConfigModulePath = '.\05 - Pull configuration'
$Global:unifiedConfigModulePath = '.\06 - Unified configuration'

Set-Location $basePath\$envPreparationPath

Install-Module xWebAdministration

.\environmentPreparation.ps1



