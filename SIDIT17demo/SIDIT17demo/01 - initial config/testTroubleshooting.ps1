configuration testTroubleshooting {
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node ('localhost') {
        Registry HKCU_regKey
        {
            Ensure = 'Present'
            Key = 'HKEY_CURRENT_USER\SOFTWARE\ExampleKey'
            ValueName = 'TestValue'
            ValueData = 'TestData'
        }
    }

}

