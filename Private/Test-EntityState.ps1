function Test-EntityState() {
<#
.DESCRIPTION
    Uses OVF to invoke Pester tests on a specific Tests file. Provided via the TestFilePath parameter.
.INPUTS
    <none>
.OUTPUTS
    Either:

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
    [OutputType([Boolean])]
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

    $state = $true
    if ($null -ne $ovfTestOutput.Result) {
        if ($ovfTestOutput.Result -eq "Failed") {
            $state = $false

            # Report that the IT Service/Entity was found to be in a failed state
            #Submit-EntityStateReport
        }

        $state
    } else {
        throw "The OperationValidation result contains no result data."
    }
}