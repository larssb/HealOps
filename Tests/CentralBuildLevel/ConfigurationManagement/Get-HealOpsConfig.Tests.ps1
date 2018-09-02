# Define variables
$moduleRoot = $($Settings.moduleRoot)

# Tests
Describe "Get-HealOpsConfig" {

    It "Executes cleanly" {
        # Call Get-HealOpsConfig to get the HealOps config file.
        { [PSCustomObject]$global:HealOpsConfig = Get-HealOpsConfig -ModuleBase $moduleRoot } | Should Not Throw
    }

    It "Returns the HealOps config file" {
        #
        $HealOpsConfig | Should -Not -BeNullOrEmpty
    }

    It "Is a proper HealOps config file" {
        #
        $HealOpsConfig.Metrics.System | Should -Not -BeNullOrEmpty
    }
}