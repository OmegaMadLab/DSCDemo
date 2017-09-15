Set-Location $basePath\$securityModulePath

# Adding a dummy AD user
$scriptBlock = {
New-AdUser -Name 'testUser' `
            -Enabled $true `
            -AccountPassword (ConvertTo-SecureString 'Passw0rd' -AsPlainText -force)  
}
Invoke-Command -ComputerName $DC -ScriptBlock $scriptBlock

start-process iexplore.exe file://$basePath/$securityModulePath/demo03.jpg

#### Change runas account for a Windows service
ise .\changeServiceRunAsAccount.ps1

# Applying configuration
. .\changeServiceRunAsAccount.ps1
changeServiceRunAsAccount -serviceName 'AudioSrv' -serviceAccount (Get-Credential)

# Unsecure method! Switching to plain text password
ise .\changeServiceRunAsAccount_plainText.ps1

$secpasswd = ConvertTo-SecureString 'Pssw0rd' -AsPlainText -Force
$svcAcctnCred = New-Object System.Management.Automation.PSCredential ("$($domainName)\testUser", $secpasswd)

. .\changeServiceRunAsAccount_plainText.ps1
changeServiceRunAsAccount_plainText -ConfigurationData $configData -serviceName 'AudioSrv' -serviceAccount $svcAcctnCred
Start-DscConfiguration -Path .\changeServiceRunAsAccount_plainText -Wait -Force -Verbose

ise .\changeServiceRunAsAccount_plainText\$($fe01).mof

# Enhancing security with certificates
ise .\changeServiceRunAsAccount_certificate.ps1

# Creating a local folder to hosts public key for DSC certificates
$certFolderName = "C:\Certificates"

if(!(Test-Path $certFolderName))
{
    $certFolder = New-Item -Path "C:\Certificates" -ItemType Directory
    $certFolderName = $certFolder.FullName
}

# ise .\helperScripts.ps1
# Generating a self signed certificate for DSC purposes on remote machine, and export public key on local server
. .\helperScripts.ps1

$dscCert = createAndGetCertificate -remoteComputerName $FE01 `
                                    -localCertPath $certFolderName

start-process explorer.exe $certFolderName

# Loading configuration
. .\changeServiceRunAsAccount_certificate.ps1

# Updating parameters related to certificate
($configData.AllNodes | ? {$_.nodeName -eq $FE01}).Thumbprint = $dscCert.Thumbprint
($configData.AllNodes | ? {$_.nodeName -eq $FE01}).CertificateFile = $dscCert.FullName

$configData.AllNodes

changeServiceRunAsAccount_certificate -ConfigurationData $configData -serviceName 'AudioSrv' -serviceAccount $svcAcctnCred
ise .\changeServiceRunAsAccount_certificate\sidit17-fe01.sidit17.local.mof

# Applying LCM configuration to the target node
Set-DscLocalConfigurationManager .\changeServiceRunAsAccount_certificate -Verbose 

# Applying configuration to the target node
Start-DscConfiguration -Path .\changeServiceRunAsAccount_certificate -Wait -Force -Verbose

# Check
$scriptBlock = {
    Get-WmiObject Win32_Service | ? {$_.Name -eq 'AudioSrv'} | Select-Object Name, StartName, StartMode
}
invoke-command -computerName $FE01 -scriptBlock $scriptBlock

