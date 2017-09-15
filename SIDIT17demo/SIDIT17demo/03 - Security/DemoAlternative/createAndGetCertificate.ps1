function createAndGetCertificate {

    param (
        [string]$remoteComputerName,
        [string]$localCertPath
    )

    # Richiedo un certificato Self Signed sulla macchina remota
    $ScriptBlock = {
        New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My `
                                   -DnsName $using:remoteComputerName `
                                   -subject "CN=$using:remoteComputerName" `
                                   -FriendlyName "$using:remoteComputerName - DSC Encryption Self Signed" `
                                   -HashAlgorithm 'SHA256' `
                                   -KeyAlgorithm 'RSA' `
                                   -KeyLength 2048 `
                                   -KeyUsage 'KeyEncipherment', 'DataEncipherment' `
                                   -Provider 'Microsoft Enhanced Cryptographic Provider v1.0' `
                                   -Type 'DocumentEncryptionCert' `
                                   -TextExtension @("2.5.29.37={text}1.3.6.1.4.1.311.80.1")
    }

    Invoke-Command –ComputerName $remoteComputerName `
                        –ScriptBlock $ScriptBlock

    #Esporto in locale il certificato creato sul nodo remoto
    $cert = Invoke-Command –ComputerName $remoteComputerName `
                            –ScriptBlock {Get-Childitem –Path Cert:\LocalMachine\My -DocumentEncryptionCert | where {$_.Subject –like "CN=$using:remoteComputerName*"}} `

    $cert | Export-Certificate –FilePath "$localCertPath\$remoteComputerName.cer"

    #Importo il certificato sulla macchina locale
    Import-Certificate –FilePath "$localCertPath\$remoteComputerName.cer" –CertStoreLocation 'Cert:\LocalMachine\My'
}