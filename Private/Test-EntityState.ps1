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
        "invoke-pester failed with: $_" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        throw "Test-EntityState failed with: $_"
    }

    $state = $true
    if ($null -ne $TestOutput.TestResult) {
        #

        if ($TestOutput.FailedCount -ge 1) {
            $state = $false

            <#
                - # Transform the output from the test

                # TODO: Maybe into its own funtion!
            #>
            $TestOutputTransformed = @{}

            # Get the FailureMessage
            $FailureMessage = $TestOutput.TestResult.FailureMessage -replace ".+{","" -replace "}.+",""

            # Add the transformed to the HashTable
            $TestOutputTransformed.add("FailureMessage",$FailureMessage)

#############
            # Report that the IT Service/Entity was found to be in a failed state
            $healOpsConfig = Get-Content -Path $PSScriptRoot/../Artefacts/HealOpsConfig.json -Encoding UTF8 | ConvertFrom-Json

            # Define tags in JSON
            $tags = @{}
            $tags.Add("node",(get-hostname))

            # Call to get the metric reported to the reporting backend
            # TODO: try/catch here?
            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($TestOutput.TestResult.Describe) -tagpairs $tags -metricValue $FailureMessage
        }

        # Collect the result
        $tempCollection = @{}
        $tempCollection.Add("state",$state)
        $tempCollection.Add("testdata",$TestOutputTransformed)

        # Return to caller
        $tempCollection
    } else {
        throw "The Pester result contains no result data."
    }
}