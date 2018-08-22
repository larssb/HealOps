# Define variables
$ModuleName = $($Settings.moduleName)
$ModuleRoot = $($Settings.moduleRoot)

########
# PREP #
########
# Read-in the updated HealOps config.
if($PSVersionAbove4) {
    [PSCustomObject]$HealOpsConfig_Updated = Get-Content -Path $PSScriptRoot/HealOpsConfig_Updated.json -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
} else {
    [PSCustomObject]$HealOpsConfig_Updated = Get-Content -Path $PSScriptRoot/HealOpsConfig_Updated.json -ErrorAction Stop | Out-String -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}

# Read-in the current HealOps config.
if($PSVersionAbove4) {
    [PSCustomObject]$HealOpsConfig_Current = Get-Content -Path $PSScriptRoot/HealOpsConfig_Current.json -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
} else {
    [PSCustomObject]$HealOpsConfig_Current = Get-Content -Path $PSScriptRoot/HealOpsConfig_Current.json -ErrorAction Stop | Out-String -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}

# Compare the two configs. Their properties (this is what Compare-HealOpsConfig compares on).
[PSCustomObject]$ConfigComparisonResult = Compare-HealOpsConfig -CurrentConfig $HealOpsConfig_Current -UpdatedConfig $HealOpsConfig_Updated

#########
# Tests #
#########
Describe "Sync-HealOpsConfig" {

    It "Executes cleanly" {
        { [PSCustomObject]$global:SyncedConfig = Sync-HealOpsConfig -ConfigChanges $ConfigComparisonResult -CurrentConfig $HealOpsConfig_Current } | Should Not Throw
    }

    It "Does not return $null" {
        $SyncedConfig | Should -Not -BeNullOrEmpty
    }

    <#
        Tests on the checkForUpdates property.
    #>
    It "The CheckForUpdates property is set" {
        $SyncedConfig.checkForUpdates | Should -Not -BeNullOrEmpty
    }

    It "The CheckForUpdates should be either true or false" {
        $SyncedConfig.checkForUpdates | Should -BeOfType [bool]
    }
}