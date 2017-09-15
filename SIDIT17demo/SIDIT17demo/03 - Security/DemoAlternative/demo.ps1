cd $basePath
cd $securityModulePath

# Creo una share di rete con all'interno un file html
$shareFolder = New-Item -Path C:\Share -ItemType Directory
New-SMBShare –Name $shareFolder.Name –Path $shareFolder.FullName
New-Item -Path $shareFolder.FullName -Name "index2.htm" -ItemType File -Value "Homepage proveniente da $shareFolder"

#Provo a copiare il file suddetto nella inetpub di MO-SIDIT17-FE01
powershell_ise.exe .\SIDIT17WebSiteTest_v2.ps1
. .\SIDIT17WebSiteTest_v2.ps1
SIDIT17WebSiteTest_v2 -sourcePath "\\$($fe01)\Share\index2.htm"
Start-DscConfiguration -Path .\SIDIT17WebSiteTest_v2 -Wait -Force -Verbose

#Creo un utente di test e aggiungo il passaggio di credenziali
$scriptBlock = {
New-AdUser -Name 'testUser' `
            -Enabled $true `
            -AccountPassword (ConvertTo-SecureString 'Passw0rd' -AsPlainText -force)  
}
Invoke-Command -ComputerName 'MO-SID2017-DC' -ScriptBlock $scriptBlock

powershell_ise.exe .\SIDIT17WebSiteTest_v2cred.ps1
. .\SIDIT17WebSiteTest_v2cred.ps1
SIDIT17WebSiteTest_v2 -sourcePath "\\MO-SIDIT17-DSC\Share\index2.htm" -credential (Get-Credential)
Start-DscConfiguration -Path .\SIDIT17WebSiteTest_v2 -Wait -Force -Verbose

#Approccio non sicuro!
powershell_ise.exe .\SIDIT17WebSiteTest_v2credplaintext.ps1
. .\SIDIT17WebSiteTest_v2credplaintext.ps1
SIDIT17WebSiteTest_v2 -sourcePath "\\MO-SIDIT17-DSC\Share\index2.htm" -ConfigurationData $configData -credential (Get-Credential)
Start-DscConfiguration -Path .\SIDIT17WebSiteTest_v2 -Wait -Force -Verbose

powershell_ise.exe .\SIDIT17WebSiteTest_v2\mo-sidit17-fe01.mof

#Approccio sicuro, con certificati
powershell_ise.exe .\SIDIT17WebSiteTest_v2certificate.ps1

#Creo una cartella in locale per contenere le chiavi pubbliche dei certificati
if(!(Test-Path $certFolder))
{
    $certFolder = New-Item -Path C:\Certificates -ItemType Directory
}

#Creo un certificato self signed sulla macchina remota, ed esporto la chiave pubblica all'interno della folder creata sopra
$remoteComputerName = 'MO-SIDIT17-FE01'
$remoteComputerIp = '172.17.3.6'
$remoteComputerCredential = Get-Credential -Message "Insert credential for $($remoteComputerName):"
$localCertPath = $certFolder.FullName

. .\createAndGetCertificate.ps1

createAndGetCertificate -remoteComputerName $remoteComputerName `
                        -remoteComputerIp $remoteComputerIp `
                        -remoteComputerCredential $remoteComputerCredential `
                        -localCertPath $localCertPath

#Recupero il thumbprint del certificato
$cert = (Get-ChildItem -Path Cert:\LocalMachine\My | ?{$_.Subject -like "CN=$remoteComputerName*"})

#Leggo la configurazione
. .\SIDIT17WebSiteTest_v2certificate.ps1

#Aggiorno i parametri legati al certificato
($configData.AllNodes | ? {$_.nodeName -eq "mo-sidit17-fe01"}).Thumbprint = $cert.Thumbprint
($configData.AllNodes | ? {$_.nodeName -eq "mo-sidit17-fe01"}).CertificateFile = "$localCertPath\$remoteComputerName.cer"

$configData.AllNodes

SIDIT17WebSiteTest_v2 -sourcePath "\\MO-SIDIT17-DSC\Share\index2.htm" -ConfigurationData $configData -credential (Get-Credential -Message "Insert credential for DSC Config:")

#Applico la metaconfigurazione al LCM del target node
Set-DscLocalConfigurationManager .\SIDIT17WebSiteTest_v2 -Verbose 

#Applico la configurazione al target node
Start-DscConfiguration -Path .\SIDIT17WebSiteTest_v2 -Wait -Force -Verbose

