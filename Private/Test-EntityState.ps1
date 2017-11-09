function Test-EntityState() {
<#
.DESCRIPTION
   Invokes Pester tests on a specific Tests file. Provided via the TestFilePath parameter.
.INPUTS
    <none>
.OUTPUTS
    A Hashtable collection containing:
        - The outcome of the Pester test.
        - The Pester test output.
.NOTES
    General notes
.EXAMPLE
    $Test-EntityState -TestFilePath ./PATH/ENTITY_TO_TEST.TESTS.ps1
    Explanation of what the example does
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath
    )

    #############
    # Execution #
    #############
    try {
        # Execute the tests
        $TestOutput = Invoke-Pester $TestFilePath -PassThru -Show None
    } catch {
        # Log
        Write-Verbose -Message "Test-EntityState failed with: $_"
    }

    if ($null -ne $TestOutput.TestResult) {
        # Set state semaphore
        $state = $true

        if ($TestOutput.FailedCount -ge 1) {
            $state = $false
            # Transform the output from the failed test
            $TestOutputTransformed = @{}

            # Get the FailureMessage - should always be numeric to support TSDB's
            $FailureMessage = $TestOutput.TestResult.FailureMessage -replace ".+{","" -replace "}.+",""

            # Add the transformed failure message to the HashTable
            $TestOutputTransformed.add("FailureMessage",$FailureMessage)
        }

        # Collect the result
        $tempCollection = @{}
        $tempCollection.Add("state",$state)
        $tempCollection.Add("testdata",$TestOutputTransformed)
        $tempCollection.Add("metric",$($TestOutput.TestResult.Describe))

        # Return to caller
        $tempCollection
    } else {
        throw "The Pester result contains no result data."
    }
}