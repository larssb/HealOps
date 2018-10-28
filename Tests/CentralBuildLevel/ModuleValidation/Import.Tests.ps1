# Define variables
$ModuleName = $($Settings.ModuleName)
$ModuleRoot = $($Settings.ModuleRoot)
$ModuleVersionRoot = $($Settings.ModuleVersionRoot)

# Tests
Describe "Module '$ModuleName' can import cleanly" {
    <#
        - Tests that the module imports cleanly.
    #>
    It "Module '$ModuleName' can import cleanly" {
        # Assertion
        { Import-Module -Name $ModuleRoot -Force -Scope Local -ErrorAction Stop } | Should Not Throw
    }
}