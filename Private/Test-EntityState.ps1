function Test-EntityState() {
<#
.DESCRIPTION
   Invokes Pester tests on a specific Tests file. Provided via the TestFilePath parameter.
.INPUTS
    <none>
.OUTPUTS
    If the Pester test resulted in a verification of an okay state of the tested entity.
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
        # Execute the tests
        $PesterTestOutput = Invoke-Pester $TestFilePath -PassThru -Show None
    } catch {
        # Log
        "invoke-pester failed with: $_" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        throw "Test-EntityState failed with: $_";
    }

    $state = $true
    #if ($null -ne $ovfTestOutput.Result) {
    if ($null -ne $PesterTestOutput.TestResult) {
        if ($PesterTestOutput.FailedCount -ge 1) {
            $state = $false

            # TODO: Maybe parse the Pester TestResult output here.....or into its own function

            # Report that the IT Service/Entity was found to be in a failed state
            $healOpsConfig = Get-Content -Path $PSScriptRoot/../Artefacts/HealOpsConfig.json -Encoding UTF8 | ConvertFrom-Json
            $metricValue = $PesterTestOutput.TestResult.FailureMessage -replace ".+{","" -replace "}.+",""

            # Define tags in JSON
            $tags = @{}
            $tags.Add("node",(get-hostname))

            # Call to get the metric reported to the reporting backend
            # TODO: try/catch here?
            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($PesterTestOutput.TestResult.Describe) -tagpairs $tags -metricValue $metricValue
        }

        # Return the result to caller
        $state
    } else {
        throw "The Pester result contains no result data."
    }
}