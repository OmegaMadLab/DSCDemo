function createDscCertTemplate {

    param (
        [ValidateNotNullOrEmpty()]
        [string] $templateName
    )
    
    #Generate a 1-year DSC Encryption certificate template
    $dscTemplateName = $templateName

    $ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
    $ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

    $dscTemplate = $ADSI.Create("pKICertificateTemplate", "CN=$dscTemplateName") 
    $dscTemplate.put("distinguishedName","CN=$dscTemplateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 
    $dscTemplate.put("flags","131680")
    $dscTemplate.put("displayName","DscEncryptionTemplate")
    $dscTemplate.put("revision","100")
    $dscTemplate.put("pKIDefaultKeySpec","1")
    $dscTemplate.SetInfo()

    $dscTemplate.put("pKIMaxIssuingDepth","0")
    $dscTemplate.put("pKICriticalExtensions","2.5.29.15")
    $dscTemplate.put("pKIKeyUsage", [byte[]]"48")
    $dscTemplate.put("pKIExtendedKeyUsage","1.3.6.1.4.1.311.80.1")
    $dscTemplate.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")
    $dscTemplate.put("msPKI-RA-Signature","0")
    $dscTemplate.put("msPKI-Enrollment-Flag","32")
    $dscTemplate.put("msPKI-Private-Key-Flag","16842752")
    $dscTemplate.put("msPKI-Certificate-Name-Flag","1207959552")
    $dscTemplate.put("msPKI-Minimal-Key-Size","2048")
    $dscTemplate.put("msPKI-Template-Schema-Version","2")
    $dscTemplate.put("msPKI-Template-Minor-Revision","1")
    $dscTemplate.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.344509.2520741.5521572.13453375.4270371.136.3000754.9305404")
    $dscTemplate.put("msPKI-Certificate-Application-Policy","1.3.6.1.4.1.311.80.1")
    $dscTemplate.put("pKIExpirationPeriod",[byte[]] ("0 64 57 135 46 225 254 255").Split(" "))
    $dscTemplate.put("pKIOverlapPeriod",[byte[]] ("0 128 166 10 255 222 255 255").Split(" "))
    $dscTemplate.SetInfo()

    #Assign autoenrollment to Domain Computers group
    $AdObj = New-Object System.Security.Principal.NTAccount("Domain Computers")
    $identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
    $adRights = "ReadProperty, WriteProperty, ExtendedRight"
    $type = "Allow"

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)
    $dscTemplate.psbase.ObjectSecurity.SetAccessRule($ACE)
    $dscTemplate.psbase.commitchanges()

}

function getAndZipModule() {

    param (
            [Parameter(Mandatory = $true)]
            [String[]] $dscModuleNames,

            [Parameter(Mandatory = $true)]
            [String] $dscPullSrvModulePath
        )

    forEach($dscModuleName in $dscModuleNames) {

        # Installing module
        Install-Module $dscModuleName
        $dscModule = Get-Module $dscModuleName -ListAvailable
        $dscModulePath = $dscModule.ModuleBase+'\*'

        # Zip module with [moduleName]_[Version].zip naming convention inside DSC Pull server module repository
        $dscModuleZip = "$($dscPullSrvModulePath)\$($dscModule.Name)_$($dscModule.Version).zip"
        Compress-Archive -Path $dscModulePath  -DestinationPath $dscModuleZip -Force

        # Generating checksum for zip file
        New-DscChecksum -Path $dscModuleZip

    }

}