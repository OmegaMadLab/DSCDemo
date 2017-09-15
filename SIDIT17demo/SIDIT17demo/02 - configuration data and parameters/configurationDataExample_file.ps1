Configuration configurationDataExample_variable {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    
    Node $AllNodes.NodeName {

        WindowsFeature WebServer {
            Ensure          = "Present"
            Name            =    "Web-Server"
        }

        File WebsiteContent {
            Ensure          = 'Present'
            DestinationPath = $node.HtmlPath
            Contents        = $node.HtmlContent
            Force           = $true
        }
    }
} 
