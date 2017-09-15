configuration loadBalancedWebSite {

    param (
        [Parameter(Mandatory = $true)]
        [String] $sourceFolder,

        [Parameter(Mandatory = $true)]
        [String] $hostHeader

    )

    Import-DscResource -Module PSDesiredStateConfiguration, xNetworking, xWebAdministration

    Node loadBalancedWebSiteConfig {
    
        WindowsFeature IIS {
            Name                 = 'web-server'
            Ensure               = 'present'
            IncludeAllSubFeature = $true
        }

        xWebsite DefaultSite 
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Stopped'
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]IIS'
        }

        file WebSiteContent
        {
            Type            = 'Directory'
            SourcePath      = $sourceFolder
            DestinationPath = "C:\Inetpub\wwwroot\$hostHeader"
            Ensure          = 'Present'
            DependsOn       = '[WindowsFeature]IIS'
            MatchSource     =  $true
            Recurse         = $true
        }

        xWebsite testSite {
            Name            = 'loadBalancedWebSite'
            PhysicalPath    = 'C:\Inetpub\wwwroot\loadBalancedWebSite'
            BindingInfo     = MSFT_xWebBindingInformation
            {
                Protocol    = 'http'
                Port        = '80'
                HostName    = $hostHeader
            }
            State           = 'started'
            Ensure          = 'Present'
            DependsOn       = '[File]WebSiteContent'
        }

        xHostsFile hostEntry {
            HostName        = $hostheader
            Ensure          = 'Absent'
        }
    
    }
}