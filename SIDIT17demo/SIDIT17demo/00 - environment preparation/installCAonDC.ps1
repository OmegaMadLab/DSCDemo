Add-WindowsFeature AD-Certificate -IncludeAllSubFeature -IncludeManagementTools

Install-CertificationAuthority -CAName "SIDIT17-Root-CA" -CADNSuffix "OU=Information Systems, O=Sysadmins, C=IT" `
    -CAType "Enterprise Root" -ValidForYears 10

Start-Sleep -Seconds 10

certutil -setreg policy\EditFlags +EDITF_ATTRIBUTESUBJECTALTNAME2
net stop certsvc
net start certsvc