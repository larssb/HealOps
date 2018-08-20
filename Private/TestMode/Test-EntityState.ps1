function Test-EntityState() {
<#
.DESCRIPTION
    Invokes Pester on a specific *.Tests.ps1 file. Provided via the TestFilePath parameter.
.INPUTS
    [String]TestFilePath. Representing the path to a *.Tests.ps1 file.
.OUTPUTS
    A Hashtable collection containing:
        - The outcome of the Pester test.
        - The Pester test output.
.NOTES
    <none>
.EXAMPLE
    PS C:\> Test-EntityState -TestFilePath ./PATH/ENTITY_TO_TEST.TESTS.ps1
    Executes Test-EntityState which executes the tests in the *.Tests.ps1 file in order to determine if an IT system/component is in a failed state.
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$TestFilePath
    )

    #############
    # Execution #
    #############
    try {
        # Execute the tests
        $currentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
        $TestOutput = Invoke-Pester $TestFilePath -PassThru -Show None -ErrorAction Stop
    } catch {
        Write-Verbose -Message "Test-EntityState | Invoke-Pester failed with: $_"
        throw "Test-EntityState | Invoke-Pester failed with: $_"
    } finally {
        $ErrorActionPreference = $currentErrorActionPreference
    }

    if ($null -ne $TestOutput.TestResult) {
        # Set a state semaphore
        $state = $true

        if ($TestOutput.FailedCount -ge 1) {
            # Set the state to report to false
            $state = $false

            # Retrieve the failed test value to report to the backend (HealOps requires the value to be numeric)
            $log4netLoggerDebug.debug("Test-EntityState | The failuremessage in the Pester output is > $($TestOutput.TestResult.FailureMessage)")
            if ((Get-Variable -Name failedTestResult -ErrorAction SilentlyContinue)) {
                $testData = $failedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                $log4netLoggerDebug.debug("Test-EntityState | failedTestResult value > $failedTestResult set in *.Tests.ps1 file > $TestFilePath")
                Write-Verbose -Message "Test-EntityState | failedTestResult > $failedTestResult"
            } else {
                # TODO: Log IT and inform x!
                $testData = -2 # Value indicating that the global variable failedTestResult was not set correctly in the *.Tests.ps1 file.
                $log4netLogger.error("Test-EntityState | The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                Write-Verbose -Message "Test-EntityState | The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
            }
        } else {
            # Retrieve the passed test value to report to the backend (HealOps requires the value to be numeric)
            if ((Get-Variable -Name passedTestResult -ErrorAction SilentlyContinue)) {
                $testData = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                $log4netLoggerDebug.debug("Test-EntityState | passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestFilePath")
                Write-Verbose -Message "Test-EntityState | passedTestResult > $passedTestResult"
            } else {
                # TODO: Log IT and inform x!
                $testData = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                $log4netLogger.error("Test-EntityState | The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                Write-Verbose -Message "Test-EntityState | The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
            }
        }

        # Collect the result
        $tempCollection = @{}
        $tempCollection.Add("state",$state)
        $tempCollection.Add("testdata",$testData)
        $tempCollection.Add("metric",$($TestOutput.TestResult.Describe))

        # Return to caller
        $tempCollection
    } else {
        throw "Test-EntityState | Failed with: The Pester result contains no result data."
    }
}