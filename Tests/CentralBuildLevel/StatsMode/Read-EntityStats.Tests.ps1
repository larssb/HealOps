# Define variables
$ModuleName = $($Settings.moduleName)
$ModuleRoot = $($Settings.moduleRoot)

# Tests
Describe "Read-EntityStats" {

    It "Executes cleanly" {
        { [PSCustomObject]$global:Stats = Read-EntityStats -StatsFilePath $PSScriptRoot/Read-EntityStats.Helper.ps1 } | Should Not Throw
    }

    It "Does not return $null" {
        $Stats | Should -Not -BeNullOrEmpty
    }
}