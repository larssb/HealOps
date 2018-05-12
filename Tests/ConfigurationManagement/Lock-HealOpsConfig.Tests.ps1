Import-Module -name $PSScriptRoot/../healops -force

InModuleScope healops {
    Describe "Lock-HealOpsConfig" {

        It "Executes cleanly" {
            # Call Get-HealOpsConfig to get the HealOps config file.
            { [PSCustomObject]$global:HealOpsConfig = Get-HealOpsConfig -ModuleBase $PSScriptRoot/../ -verbose } | Should Not Throw
        }

        It "Returns the HealOps config file" {
            #
            $HealOpsConfig | Should -Not -BeNullOrEmpty
        }

        It "Is a proper HealOps config file" {
            #
            $HealOpsConfig.reportingBackend | Should -Not -BeNullOrEmpty
        }
    }
}