# Define variables
$ModuleName = $($Settings.ModuleName)
$ModuleRoot = $($Settings.ModuleRoot)

# Tests
Describe "Module '$moduleName' can import cleanly" {
    <#
        - Tests that the module imports cleanly.
    #>
    It "Module '$moduleName' can import cleanly" {
        # Assertion
        { Import-Module -Name $ModuleRoot -Force -Scope Local -ErrorAction Stop } | Should Not Throw
    }
}