# Define variables
$ModuleRoot = $($Settings.ModuleRoot)
$ModuleVersionRoot = $($Settings.ModuleVersionRoot)

# Tests
Describe "Lock-HealOpsConfig" {

    It "Executes cleanly" {
        # Call Get-HealOpsConfig to get the HealOps config file.
        { [System.IO.FileStream]$global:HealOpsConfigFile = Lock-HealOpsConfig -HealOpsConfigPath $ModuleVersionRoot/Artefacts/HealOpsConfig.json -Verbose } | Should Not Throw
    }
}