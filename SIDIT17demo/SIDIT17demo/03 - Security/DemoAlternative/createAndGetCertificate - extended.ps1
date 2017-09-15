function createAndGetCertificate {

    param (
        [string]$remoteComputerName,
        [string]$remoteComputerIp,
        [bool] $useCallerCredential,
        [PSCredential]$remoteComputerCredential,
        [string]$localCertPath
    )

    # Aggiungo entry nel file hosts
    $hosts = "$env:windir\system32\drivers\etc\hosts"
    if (!(Get-Content $hosts | Where-Object {$_ -like "*$remoteComputerName*"})) {
        $remoteComputerIp + " " + $remoteComputerName | Add-Content -PassThru $hosts
    }

    # Aggiungo il server come TrustedHosts per WinRM
    $currentTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).value
    if (!$currentTrustedHosts.Contains($remoteComputerName)) {
        $updatedTrustedHosts = $currentTrustedHosts + ",$remoteComputerName" 
        Set-item WSMan:\localhost\Client\TrustedHosts –value $updatedTrustedHosts -Force
    }

    # Richiedo un certificato Self Signed sulla macchina remota
    $ScriptBlock = {
        New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My `
                                   -DnsName $env:COMPUTERNAME `
                                   -subject "CN=$env:COMPUTERNAME" `
                                   -FriendlyName "$env:COMPUTERNAME - DSC Encryption Certifificate" `
                                   -HashAlgorithm 'SHA256' `
                                   -KeyAlgorithm 'RSA' `
                                   -KeyLength 2048 `
                                   -KeyUsage 'KeyEncipherment', 'DataEncipherment' `
                                   -Provider 'Microsoft Enhanced Cryptographic Provider v1.0' `
                                   -Type 'DocumentEncryptionCert' `
                                   -TextExtension @("2.5.29.37={text}1.3.6.1.4.1.311.80.1")
    }

    if($useCallerCredential) {
        Invoke-Command –ComputerName $remoteComputerName `
                        –ScriptBlock $ScriptBlock
    }
    else {
        Invoke-Command –ComputerName $remoteComputerName `
                        –ScriptBlock $ScriptBlock `
                        -Credential $remoteComputerCredential
    }

    #Esporto in locale il certificato creato sul nodo remoto
    $cert = Invoke-Command –ComputerName $remoteComputerName `
                            –ScriptBlock {Get-Childitem –Path Cert:\LocalMachine\My | where {$_.Subject –eq "CN=$env:COMPUTERNAME"}} `
                            -Credential $remoteComputerCredential

    $cert | Export-Certificate –FilePath "$localCertPath\$remoteComputerName.cer"

    #Importo il certificato sulla macchina locale
    Import-Certificate –FilePath "$localCertPath\$remoteComputerName.cer" –CertStoreLocation 'Cert:\LocalMachine\My'
}