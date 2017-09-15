# This is a very basic Configuration to deploy a pull server instance in a lab environment on Windows Server 2012.
# Taken from https://msdn.microsoft.com/it-it/powershell/dsc/secureserver
# added UseSecurityBestPractices = $false as per new resource version

Configuration PullServer {
Import-DscResource -ModuleName xPSDesiredStateConfiguration

        # Load the Windows Server DSC Service feature
        WindowsFeature DSCServiceFeature
        {
          Ensure                   = 'Present'
          Name                     = 'DSC-Service'
        }

        # Use the DSC Resource to simplify deployment of the web service
        xDSCWebService PSDSCPullServer
        {
          Ensure                   = 'Present'
          EndpointName             = 'PSDSCPullServer'
          Port                     = 8080
          PhysicalPath             = "$env:SYSTEMDRIVE\inetpub\wwwroot\PSDSCPullServer"
          CertificateThumbPrint    = 'AllowUnencryptedTraffic'
          ModulePath               = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
          ConfigurationPath        = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
          State                    = 'Started'
          UseSecurityBestPractices = $false
          DependsOn                = '[WindowsFeature]DSCServiceFeature'
        }
}
PullServer -OutputPath 'C:\PullServerConfig\'
Start-DscConfiguration -Wait -Force -Verbose -Path 'C:\PullServerConfig\'