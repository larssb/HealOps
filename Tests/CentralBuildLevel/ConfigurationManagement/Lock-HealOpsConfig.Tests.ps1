# Define variables
$moduleRoot = $($Settings.moduleRoot)

# Tests
Describe "Lock-HealOpsConfig" {

    It "Executes cleanly" {
        # Call Get-HealOpsConfig to get the HealOps config file.
        { [System.IO.FileStream]$global:HealOpsConfigFile = Lock-HealOpsConfig -HealOpsConfigPath $moduleRoot/Artefacts/HealOpsConfig.json -verbose } | Should Not Throw
    }
}