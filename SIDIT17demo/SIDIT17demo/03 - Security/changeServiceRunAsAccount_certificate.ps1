configuration changeServiceRunAsAccount_certificate {

    param (

        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [string] $serviceName,

        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PSCredential] $serviceAccount 
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node ($AllNodes.NodeName) {

        service ServiceToChange
        {
            Name        = $serviceName
            Ensure      = 'Present'
            State       = 'Stopped'
            Credential  = $serviceAccount
        }

        # Pass the certificate thumbprint to LCM for decryption
        LocalConfigurationManager 
        { 
            CertificateId = $node.Thumbprint 
        }
    }

}

# Configuration for certificates
$configData = @{
 
    AllNodes = @(
        @{
            NodeName = $FE01
            #Certificate containing public key needed to encrypt configuration - modified at runtime
            CertificateFile = 'filePlaceHolder'
            #Thumbprint of the certificate which will identitify it on target system - modified at runtime
            Thumbprint = 'thumbprintPlaceHolder'
            #To avoid Domain user warning
            PSDscAllowDomainUser = $true
        }
    )
}