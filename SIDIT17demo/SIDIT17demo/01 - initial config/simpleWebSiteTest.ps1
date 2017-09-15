Configuration simpleWebsiteTest {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node $FE01 {

        # The first resource block ensures that the Web-Server (IIS) feature is enabled.
        WindowsFeature WebServer {
            Ensure          = "Present"
            Name            =    "Web-Server"
        }

        # The second resource block ensures the creation of the home page HTML file.
        File WebsiteContent {
            Ensure          = 'Present'
            DestinationPath = 'c:\inetpub\wwwroot\index.htm'
            Contents        = '<head></head><body><p>Hello World from SID 2017!</p></body>'
            Force           = $true
            DependsOn       = "[WindowsFeature]WebServer"
        }
    }
} 
