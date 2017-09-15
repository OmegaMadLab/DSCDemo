Configuration warmup {

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node ($FE01, $FE02, $BE01, $BE02, $NDJSRV.name, $DSC, $DEVENV) 
    {

        WindowsFeature IIS
        {
            Name            = 'web-server'
            Ensure          = 'present'
        }

        WindowsFeature AspNet45
        {
            Name            = 'web-asp-net45'
            Ensure          = 'Present'
        }

        WindowsFeature IISmgmt
        {
            Name            = "Web-mgmt-console"
            Ensure          = 'Present'
        }

    }

    Node ($BE01, $BE02, $DEVENV) 
    {
        
        WindowsFeature aspNet45WCF
        {
            Name                    = 'NET-WCF-Services45'
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        }
    
    }

    Node ($DSC)
    {
        WindowsFeature dscService
        {
            Name    = 'DSC-service'
            Ensure  = 'Present'
        }
    }

}

warmup

Start-DscConfiguration .\Warmup -Force