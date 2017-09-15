Configuration badApproach {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    
    Node ($FE01, $FE02) {

        WindowsFeature WebServer {
            Ensure          = "Present"
            Name            =    "Web-Server"
        }

        File WebsiteContent {
            Ensure          = 'Present'
            DestinationPath = 'c:\inetpub\wwwroot\index.htm'
            Contents        = '<head></head><body><p>Hello World from SID 2017!</p></body>'
            Force           = $true
        }
    }

} 
