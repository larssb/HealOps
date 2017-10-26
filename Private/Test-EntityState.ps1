function Test-EntityState() {
<#
.DESCRIPTION
    Uses OVF to invoke Pester tests on a specific Tests file. Provided via the TestFilePath parameter.
.INPUTS
    <none>
.OUTPUTS
    Either:
        a) A System.Array containing the failed OVF test/s or
        b) An empty System.Array
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Array])]
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
        $ovfTestOutput = Invoke-OperationValidation -testFilePath $TestFilePath
    } catch {
        # Log
        "invoke-operationValidation failed with: $_" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        throw "Test-EntityState failed with: $_";
    }

    if ($null -ne $ovfTestOutput.Result) {
        # Parse the results & .add() only failed tests, if any, to a temp. collection
        $result = New-Object System.Collections.ArrayList
        $index = 0
        foreach ($test in $ovfTestOutput) {
            if ($test.Result -eq "Failed") {
                <#
                    Create PSCustomobject in order to add an ID number to a failed test.
                    A top-down hierarchy approach is in effect. Order in *.Tests.ps1 file will be the same order in the OVF output. So when iterating
                    We can simply match the Array index to order in *.Tests.ps1 file.
                #>
                $tempObject = [PSCustomObject]@{Name=$test.Name;Result=$test.Result;ID=$index}
                $result.Add($tempObject) | Out-Null

                # Report that the IT Service/Entity was found to be in a failed state
                #Submit-ServiceStateReport
            }
            $index++
        }
        $result
    } else {

    }
}