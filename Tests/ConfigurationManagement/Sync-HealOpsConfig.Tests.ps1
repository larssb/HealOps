# Define variables
$moduleName = $($Settings.moduleName)
$moduleRoot = $($Settings.moduleRoot)

# Tests
Describe "Sync-HealOpsConfig" {

    It "Executes cleanly" {
        { [PSCustomObject]$updatedHealOpsConfig = Get-HealOpsConfig -ModuleBase $ModuleBase -verbose }
        { [PSCustomObject]$updatedHealOpsConfig = Get-HealOpsConfig -ModuleBase $ModuleBase -verbose }
        { [PSCustomObject]$global:SyncedConfig = Sync-HealOpsConfig -configChanges (Compare-HealOpsConfig -CurrentConfig $PSScriptRoot/HealOpsConfig_Current.json -UpdatedConfig $PSScriptRoot/HealOpsConfig_Changed.json) -currentConfig $PSScriptRoot/HealOpsConfig_Current.json } | Should Not Throw
    }

    It "Does not return $null" {
        $SyncedConfig | Should -Not -BeNullOrEmpty
    }

    <#
        Tests on the checkForUpdates property.
    #>
    It "Has the checkForUpdates property" {
        $SyncedConfig.checkForUpdates | Should -Not -BeNullOrEmpty
    }

    It "Should be either true or false" {
        $SyncedConfig.checkForUpdates -as [bool] | Should -BeOfType [bool]
    }
}