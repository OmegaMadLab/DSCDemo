Configuration parameterExample {

    param (
        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [string[]] $computerName 
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration
    
    Node ($computerName) {

        WindowsFeature WebServer {
            Ensure          = "Present"
            Name            =    "Web-Server"
        }

        File WebsiteContent {
            Ensure          = 'Present'
            DestinationPath = 'c:\inetpub\wwwroot\index.htm'
            Contents        = '<head></head><body><p>Hello World from SID 2017!</p></body>'
            Force           = $true
            DependsOn       = '[WindowsFeature]WebServer'
        }
    }
} 
