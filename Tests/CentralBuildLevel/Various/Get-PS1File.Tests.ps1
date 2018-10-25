# Define variables
$ModuleName = $($Settings.ModuleName)
$ModuleRoot = $($Settings.ModuleRoot)

# Tests
Describe "Get-PS1File" {

    It "Executes cleanly" {
        { [PSCustomObject]$Global:PS1File = Get-PS1File -FileName Get-PS1File -ModuleName $ModuleName } | Should Not Throw
    }

    It "Does not return $null" {
        $PS1File | Should -Not -BeNullOrEmpty
    }
}