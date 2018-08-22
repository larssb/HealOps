# Define variables
$moduleName = $($Settings.moduleName)
$moduleRoot = $($Settings.moduleRoot)

# Tests
Describe "Module '$moduleName' can import cleanly" {
    <#
        - Tests that the module imports cleanly.
    #>
    It "Module '$moduleName' can import cleanly" {
        # Assertion
        { Import-Module -Name $moduleRoot -force -ErrorAction Stop } | Should Not Throw
    }
}