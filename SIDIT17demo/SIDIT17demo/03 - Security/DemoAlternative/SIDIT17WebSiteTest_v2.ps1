Configuration SIDIT17WebsiteTest_v2 {

    param (
        [String]$sourcePath
    )

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node $fe01 {

        # The first resource block ensures that the Web-Server (IIS) feature is enabled.
        WindowsFeature WebServer {
            Ensure = "Present"
            Name =    "Web-Server"
        }

        # The second resource block ensures the creation of the home page HTML file.
        File WebsiteContent {
            Ensure = 'Present'
            SourcePath = $sourcePath
            DestinationPath = 'c:\inetpub\wwwroot'
            Type = 'file'
            Force = $true
        }
    }
} 
