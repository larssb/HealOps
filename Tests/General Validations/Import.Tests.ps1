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
        {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force -ErrorAction Stop } | Should Not Throw
    }
}