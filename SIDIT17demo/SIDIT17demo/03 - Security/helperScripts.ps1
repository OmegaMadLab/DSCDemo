function createAndGetCertificate {

    param (
        [string]$remoteComputerName,
        [string]$localCertPath
    )

    # Generating a self signed certificate on target node
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

    $null = Invoke-Command –ComputerName $remoteComputerName `
                            –ScriptBlock $ScriptBlock                 

    # Getting remote certificate and exporting it on $localCertPath
    $ScriptBlock = {
        Get-Childitem –Path Cert:\LocalMachine\My -DocumentEncryptionCert | where {$_.Subject –like "CN=$using:remoteComputerName*"}
    }

    $cert = Invoke-Command –ComputerName $remoteComputerName `
                            –ScriptBlock $ScriptBlock

    $cert | Export-Certificate –FilePath "$localCertPath\$remoteComputerName.cer" | Out-Null

    # Returning certificate thumbprint and full path
    $retVal = @{
        FullName = "$localCertPath\$remoteComputerName.cer"
        Thumbprint = $cert.thumbprint
    }

    Return $retVal
}