Import-Module -name $PSScriptRoot/../healops -force

Describe "Get-HealOpsConfig" {
    <#
        - Tests the Get-HealOpsConfig function
    #>
    It "Can import cleanly" {
        # Import the module
        {. $PSScriptRoot/../Private/ConfigurationManagement/Get-HealOpsConfig.ps1 } | Should Not Throw
    }

    It "Executes cleanly" {
        # Call Get-HealOpsConfig to get the HealOps config file.
        { [PSCustomObject]$HealOpsConfig = Get-HealOpsConfig -ModuleBase $PSScriptRoot/../ -verbose } | Should Not Throw
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