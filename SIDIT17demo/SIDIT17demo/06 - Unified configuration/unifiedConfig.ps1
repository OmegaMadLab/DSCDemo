configuration webAppDeploy {

    param (
        [Parameter(Mandatory = $true)]
        [String] $sourcePath,

        [Parameter(Mandatory = $true)]
        [String] $webSitePath,

        [Parameter(Mandatory = $true)]
        [String] $appPoolName,

        [Parameter(Mandatory = $true)]
        [String] $webSiteName,

        [Parameter(Mandatory = $true)]
        [String] $webSiteHostHeader,
        
        [Parameter(Mandatory = $true)]
        [String] $webAppName,

        [Parameter(Mandatory = $false)]
        [Bool] $sslEnabled = $false,

        [Parameter(Mandatory = $false)]
        [string] $pfxPath,

        [Parameter(Mandatory = $false)]
        [string] $pfxThumbprint,

        [Parameter(Mandatory = $false)]
        [PSCredential] $pfxCreds

    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xWebAdministration, xCertificate

    file WebAppFolder
    {
        SourcePath      = $sourcePath 
        DestinationPath = "$($webSitePath)\$($webAppName)"
        Ensure          = 'Present'
        Type            = 'Directory'
        Recurse         = $true
        MatchSource     = $true
        Force           = $true
    }

    xWebAppPool AppPool
    {
        Ensure          = 'Present'
        Name            = $appPoolName
    }

    if($sslEnabled) {

        xPfxImport sslCert
        {
            Thumbprint  = $pfxThumbprint
            Path        = $pfxPath
            Store       =  "My"
            Location    = "LocalMachine"
            Credential  = $pfxCreds
            Ensure      = "Present"
        }

        xWebsite Website 
        {
            Name            = $webSiteName
            PhysicalPath    = $webSitePath
            BindingInfo     = MSFT_xWebBindingInformation
            {
                Protocol    = 'https'
                Port        = '443'
                HostName    = $webSiteHostHeader
                CertificateThumbprint = $pfxThumbprint
            }
            State           = 'started'
            ApplicationPool = $appPoolName
            Ensure          = 'Present'
            DependsOn = '[xPfxImport]sslCert', '[xWebAppPool]AppPool'
        }

        xWebApplication Application 
        {
            Ensure                  = 'Present'
            Name                    = $webAppName
            WebAppPool              = $appPoolName
            Website                 = $webSiteName
            PreloadEnabled          = $true
            ServiceAutoStartEnabled = $true
            AuthenticationInfo      = MSFT_xWebApplicationAuthenticationInformation
            {
                Anonymous   = $true
                Basic       = $false
                Digest      = $false
                Windows     = $false
            }
            SslFlags                = @('Ssl')
            PhysicalPath            = "$($webSitePath)\$($webAppName)"
            DependsOn               = '[xWebsite]Website','[xWebAppPool]AppPool'
        }
    }
    else
    {
        xWebsite Website 
        {
            Name            = $webSiteName
            PhysicalPath    = $webSitePath
            BindingInfo     = MSFT_xWebBindingInformation
            {
                Protocol    = 'http'
                Port        = '80'
                HostName    = $webSiteHostHeader
            }
            State           = 'started'
            ApplicationPool = $appPoolName
            Ensure          = 'Present'
            DependsOn = '[xWebAppPool]AppPool'
        }

        xWebApplication Application 
        {
            Ensure                  = 'Present'
            Name                    = $webAppName
            WebAppPool              = $appPoolName
            Website                 = $webSiteName
            PreloadEnabled          = $true
            ServiceAutoStartEnabled = $true
            AuthenticationInfo      = MSFT_xWebApplicationAuthenticationInformation
            {
                Anonymous   = $true
                Basic       = $false
                Digest      = $false
                Windows     = $true
            }
            SslFlags                = ''
            PhysicalPath            = "$($webSitePath)\$($webAppName)"
            DependsOn               = '[xWebsite]Website','[xWebAppPool]AppPool'
        }
    }

}



configuration unifiedConfig {

    param (
        [PSCredential] $pfxCreds
    )

    Import-DscResource -Module PSDesiredStateConfiguration, xWebAdministration

    Node $AllNodes.NodeName
    {
        
        WindowsFeature IIS
        {
            Name            = 'web-server'
            Ensure          = 'present'
        }

        WindowsFeature AspNet45
        {
            Name = 'web-asp-net45'
            Ensure = 'Present'
        }

        WindowsFeature IISmgmt
        {
            Name = "Web-mgmt-console"
            Ensure = 'Present'
        }

        xWebsite DefaultSite 
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Stopped'
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]IIS'
        }

    }
    
    
    Node $AllNodes.Where{$_.Role -contains "frontend"}.NodeName
    { 
        if($node.sslEnabled) {
            webAppDeploy frontendWebAppSSL
            {
                sourcePath        = $Node.FrontendSourcePath
                appPoolName       = 'frontendAppPool'
                webSiteName       = 'frontendWebsite'
                webSitePath       = 'C:\inetpub\wwwroot\frontendwebsite'
                webSiteHostHeader = $Node.FrontendHostHeader
                webAppName        = 'app'
                sslEnabled        = $true
                pfxPath           = $Node.pfxPath
                pfxThumbprint     = $Node.pfxThumbprint
                pfxCreds          = $pfxCreds
                dependsOn         = '[WindowsFeature]IIS', '[WindowsFeature]aspNet45'  
            }
        }
        else
        {
            webAppDeploy frontendWebApp
            {
                sourcePath        = $Node.FrontendSourcePath
                appPoolName       = 'frontendAppPool'
                webSiteName       = 'frontendWebsite'
                webSitePath       = 'C:\inetpub\wwwroot\frontendwebsite'
                webSiteHostHeader = $Node.FrontendHostHeader
                webAppName        = 'app'
                dependsOn         = '[WindowsFeature]IIS', '[WindowsFeature]aspNet45'  
            }
        }
    }

    Node $AllNodes.Where{$_.Role -contains "backend"}.NodeName
    {
        WindowsFeature aspNet45WCF
        {
            Name                 = 'NET-WCF-Services45'
            Ensure               = 'Present'
            IncludeAllSubFeature =  $true
        }

        if($node.sslEnabled) {
            webAppDeploy backendWebAppSSL
            {
                sourcePath        = $Node.BackendSourcePath
                appPoolName       = 'backendAppPool'
                webSiteName       = 'backendWebsite'
                webSitePath       = 'C:\inetpub\wwwroot\backendwebsite'
                webSiteHostHeader = $Node.BackendHostHeader
                webAppName        = 'svc'
                sslEnabled        = $true
                pfxPath           = $Node.pfxPath
                pfxThumbprint     = $Node.pfxThumbprint
                pfxCreds          = $pfxCreds
                dependsOn         = '[WindowsFeature]IIS', '[WindowsFeature]aspNet45', '[WindowsFeature]aspNet45WCF'
            }
        }
        else
        {
            webAppDeploy backendWebApp
            {
                sourcePath        = $Node.BackendSourcePath
                appPoolName       = 'backendAppPool'
                webSiteName       = 'backendWebsite'
                webSitePath       = 'C:\inetpub\wwwroot\backendwebsite'
                webSiteHostHeader = $Node.BackendHostHeader
                webAppName        = 'svc'
                dependsOn         = '[WindowsFeature]IIS', '[WindowsFeature]aspNet45', '[WindowsFeature]aspNet45WCF'
            }
        }
    }


}

$configData = @{

    AllNodes = @(
        @{
            NodeName = "*"
            pfxPath = "\\$DSC\SourceShare\sslcert.pfx"
            pfxThumbprint = "PfxThumbPlaceholder"
        },
        @{
            NodeName = $DEVENV
            Role = "frontend", "backend"
            FrontendSourcePath = "\\$DSC\SourceShare\SampleWebSite_Test"
            FrontendHostHeader = "frontendwebsite-test.sidit17.demo"
            BackendSourcePath = "\\$DSC\SourceShare\SampleWCFService_Test"
            BackendHostHeader = "backendwebsite-test.sidit17.demo"
            sslEnabled = $false
            CertificateFile = 'filePlaceHolder'
            Thumbprint = 'thumbprintPlaceHolder'
         },
         @{
            NodeName = $FE01
            Role = "frontend"
            FrontendSourcePath = "\\$DSC\SourceShare\SampleWebSite_Prod"
            FrontendHostHeader = "frontendwebsite.sidit17.demo"
            sslEnabled = $true
            CertificateFile = 'filePlaceHolder'
            Thumbprint = 'thumbprintPlaceHolder'
         },
         @{
            NodeName = $FE02
            Role = "frontend"
            FrontendSourcePath = "\\$DSC\SourceShare\SampleWebSite_Prod"
            FrontendHostHeader = "frontendwebsite.sidit17.demo"
            sslEnabled = $true
            CertificateFile = 'filePlaceHolder'
            Thumbprint = 'thumbprintPlaceHolder'
         },
         @{
            NodeName = $BE01
            Role = "backend"
            BackendSourcePath = "\\$DSC\SourceShare\SampleWCFService_Prod"
            BackendHostHeader = "backendwebsite.sidit17.demo"
            sslEnabled = $true
            CertificateFile = 'filePlaceHolder'
            Thumbprint = 'thumbprintPlaceHolder'
         },
         @{
            NodeName = $BE02
            Role = "backend"
            BackendSourcePath = "\\$DSC\SourceShare\SampleWCFService_Prod"
            BackendHostHeader = "backendwebsite.sidit17.demo"
            sslEnabled = $true
            CertificateFile = 'filePlaceHolder'
            Thumbprint = 'thumbprintPlaceHolder'
         }

    );
    NonNodeData = @{}  
}
