Configuration sslPullServer {

    param (
        [ValidateNotNullOrEmpty()]
        [string] $certThumbPrint,

        [ValidateNotNullOrEmpty()]
        [string] $regkey
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xPSDesiredStateConfiguration, xWebAdministration
    
    Node localhost
    {

        # Install the Windows Server DSC Service feature
        WindowsFeature DSCServiceFeature
        {
            Ensure                  = 'Present'
            Name                    = 'DSC-Service'
        }

        # Use the DSC resource to simplify deployment of the web service.  You might also consider modifying the default port, possibly leveraging port 443 in environments where that is enforced as a standard.
        xDSCWebService PSDSCPullServer
        {
            Ensure                   = 'Present'
            EndpointName             = 'PSDSCPullServer'
            Port                     = 443
            PhysicalPath             = "$env:SYSTEMDRIVE\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint    = $certThumbPrint
            ModulePath               = "$env:ProgramFiles\WindowsPowerShell\DscService\Modules"
            ConfigurationPath        = "$env:ProgramFiles\WindowsPowerShell\DscService\Configuration"
            State                    = 'Started'
            UseSecurityBestPractices = $true
            DependsOn                = '[WindowsFeature]DSCServiceFeature'
        }
        
        File RegistrationKeyFile
        {
            Ensure                   = 'Present'
            Type                     = 'File'
            DestinationPath          = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents                 = $regkey
        }

        # Validate web config file contains current DB settings
        File DevicesMDB
        {
            Ensure                   = 'Present'
            Type                     = 'File'
            SourcePath               = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\PSDesiredStateConfiguration\PullServer\Devices.mdb"
            DestinationPath          = "$env:ProgramFiles\WindowsPowerShell\DscService\Devices.mdb"
            DependsOn = '[xDSCWebService]PSDSCPullServer'
        }

        xWebConfigKeyValue CorrectDBProvider
        { 
            ConfigSection = 'AppSettings'
            Key = 'dbprovider'
            Value = 'System.Data.OleDb'
            WebsitePath = 'IIS:\sites\PSDSCPullServer'
            DependsOn = '[File]DevicesMDB'
        }
        xWebConfigKeyValue CorrectDBConnectionStr
        { 
            ConfigSection = 'AppSettings'
            Key = 'dbconnectionstr'
            Value = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Program Files\WindowsPowerShell\DscService\Devices.mdb;'
            WebsitePath = 'IIS:\sites\PSDSCPullServer'
            DependsOn = '[File]DevicesMDB'
        }


    }
}

