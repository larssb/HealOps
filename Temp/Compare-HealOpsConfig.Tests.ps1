# Define variables
$moduleName = $($Settings.moduleName)
$moduleRoot = $($Settings.moduleRoot)

# Tests
Describe "TEST_NAME" {
    <#
        - TEST_DESCRIPTION
    #>
    It "EXACTLY_WHAT_IT_TESTS" {
        # A_COMMENT


        # Assertion
        $X | Should ....
    }
}