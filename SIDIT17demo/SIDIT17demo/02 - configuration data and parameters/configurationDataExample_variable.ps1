Configuration configurationDataExample_variable {

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    
    Node $AllNodes.NodeName {

        WindowsFeature WebServer {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        File WebsiteContent {
            Ensure          = 'Present'
            DestinationPath = $node.HtmlPath
            Contents        = $node.HtmlContent
            Force           = $true
            DependsOn       = '[WindowsFeature]WebServer'
        }
    }
} 

# Configuration data hash table
$MyConfigurationData = @{

    AllNodes = @(

        @{
            NodeName        = "*"
            HtmlPath        = "c:\inetpub\wwwroot\index.htm"
        },

        @{
            NodeName        = $FE01
            HtmlContent     = '<head></head><body><p>Hello World from SID 2017!</p><p>made with configuration data on node 1</p></body>'
        },

        @{
            NodeName        = $FE02
            HtmlContent     = '<head></head><body><p>Hello World from SID 2017!</p><p>made with configuration data on node 2</p></body>'
        }

    );
    NonNodeData = @{}  
}
