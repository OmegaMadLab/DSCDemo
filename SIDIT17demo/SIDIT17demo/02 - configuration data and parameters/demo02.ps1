Set-Location $basePath\$configDataParametersModulePath

start-process iexplore.exe file://$basePath/$configDataParametersModulePath/demo02.jpg

#### Bad approach, with single nodes specified
ise .\badApproach.ps1

#### Better approach
ise .\betterApproach.ps1

#### Even better, with parametrization
ise .\parameterExample.ps1

. .\parameterExample.ps1
parameterExample -computerName $fe01, $fe02

# Applying configuration
Start-DscConfiguration .\parameterExample -Wait -Force -Verbose

# Check
start-process iexplore.exe "http://$fe01/index.htm"
start-process iexplore.exe "http://$fe02/index.htm"

#### More flexibility with Configuration Data
ise .\configurationDataExample_variable.ps1

. .\configurationDataExample_variable.ps1
configurationDataExample_variable -ConfigurationData $MyConfigurationData

# Applying configuration
Start-DscConfiguration .\configurationDataExample_variable -Wait -Force -Verbose

# Check
start-process iexplore.exe "http://$fe01/index.htm"
start-process iexplore.exe "http://$fe02/index.htm"

# Putting hash table inside a PSD1 file
ise .\configurationDataExample_file.ps1
ise .\MyConfigurationData.psd1

. .\configurationDataExample_file.ps1
configurationDataExample_file -ConfigurationData .\MyConfigurationData.psd1

#### Modifying hash table at runtime
. .\configurationDataExample_variable.ps1

# Checking initial hash table
$MyConfigurationData.AllNodes

# Changing hash table
($MyConfigurationData.AllNodes | ? {$_.nodeName -eq "*"}).HtmlPath = "c:\inetpub\wwwroot\dynamicindex.htm"
($MyConfigurationData.AllNodes | ? {$_.nodeName -eq $fe01}).HtmlContent = "Content updated at runtime on first server"
($MyConfigurationData.AllNodes | ? {$_.nodeName -eq $fe02}).HtmlContent = "Content updated at runtime on second server"
$MyConfigurationData.AllNodes += @{nodeName = $be01; HtmlContent = 'Third server added at runtime'}

# Checking again 
$MyConfigurationData.AllNodes

# Applying configuration
configurationDataExample_variable -ConfigurationData $MyConfigurationData
Start-DscConfiguration .\configurationDataExample_variable -Wait -Force -Verbose

# Test post configurazione
start-process iexplore.exe "http://$fe01/dynamicindex.htm"
start-process iexplore.exe "http://$fe02/dynamicindex.htm"
start-process iexplore.exe "http://$be01/dynamicindex.htm"

# Single configuration for multiple environments
ise .\MultipleEnvironments.ps1