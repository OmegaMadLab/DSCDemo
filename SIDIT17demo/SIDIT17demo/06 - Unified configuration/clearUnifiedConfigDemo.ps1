configuration clearUnifiedConfigDemo {
    
    Import-DscResource -ModuleName PsDesiredStateConfiguration, xWebAdministration

    node ($FE01, $FE02, $BE01, $BE02, $DEVENV) {

        xWebApplication frontendWebApp
        {
            Name = 'app'
            WebSite = 'frontendWebSite'
            WebAppPool = 'frontendAppPool'
            PhysicalPath = 'C:\Inetpub\wwwroot\frontendwebsite\app'
            Ensure = 'Absent'
        }

        xWebSite frontendWebSite
        {
            Name = 'frontendWebSite'
            Ensure = 'Absent'
            DependsOn = '[xWebApplication]frontendWebApp'
        }

        xWebAppPool frontendAppPool
        {
            Name = 'frontendAppPool'
            Ensure = 'Absent'
            DependsOn = '[xWebsite]frontendWebSite'
        }

        file frontendFolder
        {
            DestinationPath = 'C:\Inetpub\wwwroot\frontendwebsite'
            Type = 'Directory'
            Ensure = 'Absent'
            DependsOn = '[xWebsite]frontendWebSite'
            Force = $true
        }

        xWebApplication backendWebApp
        {
            Name = 'svc'
            WebSite = 'backendWebSite'
            WebAppPool = 'backendAppPool'
            PhysicalPath = 'C:\Inetpub\wwwroot\frontendwebsite\svc'
            Ensure = 'Absent'
        }

        xWebSite backendWebSite
        {
            Name = 'backendWebSite'
            Ensure = 'Absent'
            DependsOn = '[xWebApplication]backendWebApp'
        }

        xWebAppPool backendAppPool
        {
            Name = 'backendAppPool'
            Ensure = 'Absent'
            DependsOn = '[xWebsite]backendWebSite'
        }

        file backendFolder
        {
            DestinationPath = 'C:\Inetpub\wwwroot\backendwebsite'
            Type = 'Directory'
            Ensure = 'Absent'
            DependsOn = '[xWebsite]backendWebSite'
            Force = $true
        }
    }
}

