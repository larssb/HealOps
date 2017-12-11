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
        Test-EntityState -TestFilePath ./PATH/ENTITY_TO_TEST.TESTS.ps1
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
            Write-Verbose -Message "Test-EntityState failed with: $_"
            throw "Test-EntityState failed with: $_"
        } finally {
            $ErrorActionPreference = $currentErrorActionPreference
        }

        if ($null -ne $TestOutput.TestResult) {
            # Set state semaphore
            $state = $true

            if ($TestOutput.FailedCount -ge 1) {
                $state = $false
                # Transform the output from the failed test
                $TestOutputTransformed = @{}

                # Retrieve the failed test value to report to the backend (should always be numeric to support TSDB's)
                $log4netLoggerDebug.debug("The failuremessage in the Pester output is > $($TestOutput.TestResult.FailureMessage)")
                if ((Get-Variable -Name failedTestResult)) {
                    $testFailedValue = $failedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                    $log4netLoggerDebug.debug("failedTestResult value > $failedTestResult set in *.Tests.ps1 file > $TestFilePath")
                    Write-Verbose -Message "failedTestResult > $failedTestResult"
                } else {
                    $testFailedValue = -1 # Value indicating that the global variable failedTestResult was not set correctly in the *.Tests.ps1 file.

                    # TODO: Log IT and inform x!
                    $log4netLogger.error("The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                    Write-Verbose -Message "The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                }

                # Add $testFailedValue to the HashTable
                $TestOutputTransformed.add("FailureMessage",$testFailedValue)
            }

            # Collect the result
            $tempCollection = @{}
            $tempCollection.Add("state",$state)
            $tempCollection.Add("testdata",$TestOutputTransformed)
            $tempCollection.Add("metric",$($TestOutput.TestResult.Describe))

            # Return to caller
            $tempCollection
        } else {
            throw "Test-EntityState failed with: The Pester result contains no result data."
        }
    }