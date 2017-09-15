#CA setup on DC
$remoteSession = New-PSSession -ComputerName $DC
Invoke-Command -Session $remoteSession -FilePath .\SetupCA.ps1
Invoke-Command -Session $remoteSession -FilePath .\installCAonDC.ps1

####WarmUp####
.\warmup.ps1

#disable IE ESC on DSC server
function Disable-IEESC
{
$AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
$UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
Stop-Process -Name Explorer
Write-Host “IE Enhanced Security Configuration (ESC) has been disabled.” -ForegroundColor Green
}
Disable-IEESC

#Share creation for demo contents
$sourceShare = New-Item -Path C:\SourceShare -ItemType Directory -Force
Copy-Item -Path .\LoadBalancedWebSite -Destination $sourceShare.FullName -Recurse -Force
Copy-Item -Path .\SampleWCFService_Prod -Destination $sourceShare.FullName -Recurse -Force
Copy-Item -Path .\SampleWCFService_Test -Destination $sourceShare.FullName -Recurse -Force
Copy-Item -Path .\SampleWebSite_Prod -Destination $sourceShare.FullName -Recurse -Force
Copy-Item -Path .\SampleWebSite_Test -Destination $sourceShare.FullName -Recurse -Force


New-SmbShare -Path $sourceShare.FullName -Name $sourceShare.Name