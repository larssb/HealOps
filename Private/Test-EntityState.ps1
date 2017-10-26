function Test-EntityState() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    Either:
        a) A System.Array containing the failed OVF test/s or
        b) An empty System.Array
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER NAME_OF_THE_PARAMETER_WITHOUT_THE_QUOTES
    Parameter HelpMessage text
    Add a .PARAMETER per parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath
    )

    #############
    # Execution #
    #############
    try {
        # Run the tests with OVF
        $ovfOutput = Invoke-OperationValidation -testFilePath $TestFilePath;
    } catch {
        # Log
        "invoke-operationValidation failed with: $_" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        throw "Test-EntityState failed with: $_";
    }

    if ($null -ne $ovfOutput.Result) {
        # Add an a ID number to tests. Needs to happen before removing okay tests. As a top-down hierarchy approach is used for id'ing tests.

        # Parse the results & .add() only failed tests, if any, to a temp. collection
        $result = @() # TODO: Should likely use System.ArrayList collection.
        foreach ($test in $ovfOutput) {

            if ($test.Result -eq "Failed") {
                $result.Add();

                # Report that the IT Service/Entity was found to be in a failed state
                Submit-ServiceStateReport
            }
        }

        # Return the result
        $result;
    } else {

    }
}