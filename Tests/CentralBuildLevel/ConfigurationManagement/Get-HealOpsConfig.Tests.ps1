# Define variables
$ModuleRoot = $($Settings.ModuleRoot)
$ModuleVersionRoot = $($Settings.ModuleVersionRoot)

# Tests
Describe "Get-HealOpsConfig" {

    It "Executes cleanly" {
        # Call Get-HealOpsConfig to get the HealOps config file.
        { [PSCustomObject]$global:HealOpsConfig = Get-HealOpsConfig -ModuleBase $ModuleVersionRoot } | Should Not Throw
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