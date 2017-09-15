[DSCLocalConfigurationManager()]

configuration pullClientConfig {

    param (
        [Parameter(Mandatory = $true)]
        [String[]] $computerName,

        [Parameter(Mandatory = $true)]
        [String] $regKey,

        [Parameter(Mandatory = $true)]
        [String] $pullUrl,

        [Parameter(Mandatory = $true)]
        [String[]] $configName
    )


    node $computerName {

        Settings
        {
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded   = $true
            AllowModuleOverwrite = $true
            ConfigurationMode    = "ApplyandAutoCorrect"
        }
        
        ConfigurationRepositoryWeb SIDIT17-PullSrv
        {
            ServerURL               = $pullUrl
            RegistrationKey         = $regKey
            AllowUnsecureConnection = $false
            ConfigurationNames      = $configName
        }

        ResourceRepositoryWeb SIDIT17-PullSrvModules
        {
            ServerURL               = $pullUrl
            RegistrationKey         = $regKey
            AllowUnsecureConnection = $false
        }

        ReportServerWeb SIDIT17-PullSrv
        {
            ServerURL       = $Node.pullUrl
            RegistrationKey = $Node.regKey
        }
        
    }

}