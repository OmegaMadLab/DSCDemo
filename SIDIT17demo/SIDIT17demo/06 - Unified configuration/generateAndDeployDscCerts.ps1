Import-Module GroupPolicy
Import-Module ActiveDirectory

# Add a dedicated OU and move computer accounts from CN=Computer
New-ADOrganizationalUnit -Name "Server"
$serverOU = Get-ADOrganizationalUnit -Filter {Name -like '*server*'}

$computerCN = Get-ADObject -Filter {Name -like '*Computer*' -and ObjectClass -eq 'container'}

$computers = Get-ADComputer -SearchBase $computerCN.DistinguishedName -filter *
$computers | % -Process {Move-ADObject -Identity $_ -targetPath $serverOU.DistinguishedName}

# Add a new autoenrollment GPO and link it on the OU
$certGpo = New-GPO -Name "EnableCertAutoenrollment"
Set-GPRegistryValue -Key "HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment" `
                    -valueName "AEPolicy" `
                    -Value 7 `
                    -Type DWord `
                    -Guid $certGpo.id

New-GPLink -Guid $certGpo.id `
            -LinkEnabled Yes `
            -Target $serverOU.DistinguishedName

# Force GPUPDATE on target computers in order to obtain certificate autoenrollment
workflow gpoRefresh {
    param (
        [string[]] $computers
    )
    
    ForEach -parallel ($computer in $computers) {
        InlineScript {Invoke-Command -computer $using:computer -scriptBlock {gpupdate /target:Computer /force}}
    }

}

gpoRefresh -computers $computers.DNSHostName
