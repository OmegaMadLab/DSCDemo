function getAndZipModule() {

    param (
            [Parameter(Mandatory = $true)]
            [String[]] $dscModuleNames,

            [Parameter(Mandatory = $true)]
            [String] $dscPullSrvModulePath
        )

    forEach($dscModuleName in $dscModuleNames) {

        # Installing module
        Install-Module $dscModuleName
        $dscModule = Get-Module $dscModuleName -ListAvailable
        $dscModulePath = $dscModule.ModuleBase+'\*'

        # Zip module with [moduleName]_[Version].zip naming convention inside DSC Pull server module repository
        $dscModuleZip = "$($dscPullSrvModulePath)\$($dscModule.Name)_$($dscModule.Version).zip"
        Compress-Archive -Path $dscModulePath  -DestinationPath $dscModuleZip -Force

        # Generating checksum for zip file
        New-DscChecksum -Path $dscModuleZip

    }