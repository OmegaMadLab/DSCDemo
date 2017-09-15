[DSCLocalConfigurationManager()]
configuration pullClientConfig_v2 {

     Node $AllNodes.NodeName {

        Settings
        {
            RefreshMode   = 'Pull'
            CertificateID = $Node.Thumbprint
        }
        
        ConfigurationRepositoryWeb SIDIT17-PullSrv
        {
            ServerURL 				= $Node.pullUrl
            RegistrationKey 		= $Node.regKey
            AllowUnsecureConnection = $false
            ConfigurationNames 		= $Node.NodeName
			CertificateID 			= $Node.Thumbprint
        }

        ResourceRepositoryWeb SIDIT17-PullSrvModules
        {
            ServerURL 				= $Node.pullUrl
            RegistrationKey 		= $Node.regKey
            AllowUnsecureConnection = $false
        }

        ReportServerWeb SIDIT17-PullSrv
        {
            ServerURL       = $Node.pullUrl
            RegistrationKey = $Node.regKey
        }
        
    }

}

$configData = @{

    AllNodes = @(
    
        @{
            NodeName        = "*"
            regKey          = Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
            pullUrl         = "https://dscpullserver.$domainName/PSDSCPullServer.svc"
        }
        <#
        @{
            NodeName        = 'nodeNamePlaceHolder'
            Thumbprint      = 'thumbprintPlaceHolder'
        }
        #>
    );
    NonNodeData = @{}  
}