configuration changeServiceRunAsAccount {

    param (

        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [string] $serviceName,

        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PSCredential] $serviceAccount 
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node ($FE01) {

        service ServiceToChange
        {
            Name        = $serviceName
            Ensure      = 'Present'
            Credential  = $serviceAccount
            State       = 'Stopped'
        }

    }

}