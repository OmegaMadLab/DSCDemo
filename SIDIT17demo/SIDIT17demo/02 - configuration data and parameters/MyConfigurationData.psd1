@{

    AllNodes = @(

        @{
            NodeName        = "*"
            HtmlPath        = "c:\inetpub\wwwroot\index.htm"
        },

        @{
            NodeName        = "mo-sidit17-fe01"
            HtmlContent     = '<head></head><body><p>Hello World from SID 2017!</p><p>made with configuration data</p></body>'
        },

        @{
            NodeName        = "mo-sidit17-fe02"
            HtmlContent     = '<head></head><body><p>Hello World from SID 2017! This server is not joined to a domain!</p><p>made with configuration data</p></body>'
        }

    );
    NonNodeData = @{}  
}