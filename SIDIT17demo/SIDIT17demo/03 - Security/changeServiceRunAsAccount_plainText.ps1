configuration changeServiceRunAsAccount_plainText {

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
            Credential  = $serviceAccount
            State       = 'Stopped'
        }

    }

}

# Configuration for plain text password
$configData = @{
 
    AllNodes = @(
        @{
            NodeName = $FE01
            PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
        }
    )
}