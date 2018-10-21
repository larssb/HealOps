# Define variables
$ModuleName = $($Settings.ModuleName)
$ModuleRoot = $($Settings.ModuleRoot)

# Tests
Describe "Read-EntityStats" {

    It "Executes cleanly" {
        { [PSCustomObject]$Global:Stats = Read-EntityStats -StatsFilePath $PSScriptRoot/Read-EntityStats.Helper.ps1 } | Should Not Throw
    }

    It "Does not return $null" {
        $Stats | Should -Not -BeNullOrEmpty
    }
}