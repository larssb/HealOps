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

            # Collection for storing failed or passed testdata
            $testData = @{}

            if ($TestOutput.FailedCount -ge 1) {
                # Set the state to report to false
                $state = $false

                # Retrieve the failed test value to report to the backend (HealOps requires the value to be numeric)
                $log4netLoggerDebug.debug("The failuremessage in the Pester output is > $($TestOutput.TestResult.FailureMessage)")
                if ((Get-Variable -Name failedTestResult -ErrorAction SilentlyContinue)) {
                    $testFailedValue = $failedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                    $log4netLoggerDebug.debug("failedTestResult value > $failedTestResult set in *.Tests.ps1 file > $TestFilePath")
                    Write-Verbose -Message "failedTestResult > $failedTestResult"
                } else {
                    # TODO: Log IT and inform x!
                    $testFailedValue = -2 # Value indicating that the global variable failedTestResult was not set correctly in the *.Tests.ps1 file.
                    $log4netLogger.error("The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                    Write-Verbose -Message "The failedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                }

                # Add $testFailedValue to the HashTable
                $testData.add($testFailedValue)
            } else {
                # Retrieve the passed test value to report to the backend (HealOps requires the value to be numeric)
                if ((Get-Variable -Name passedTestResult -ErrorAction SilentlyContinue)) {
                    $testPassedValue = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                    $log4netLoggerDebug.debug("passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestFilePath")
                    Write-Verbose -Message "passedTestResult > $passedTestResult"
                } else {
                    # TODO: Log IT and inform x!
                    $testPassedValue = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                    $log4netLogger.error("The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                    Write-Verbose -Message "The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                }

                # Add $testPassedValue to the HashTable
                $testData.add($testPassedValue)
            }

            # Collect the result
            $tempCollection = @{}
            $tempCollection.Add("state",$state)
            $tempCollection.Add("testdata",$testData)
            $tempCollection.Add("metric",$($TestOutput.TestResult.Describe))

            # Return to caller
            $tempCollection
        } else {
            throw "Test-EntityState failed with: The Pester result contains no result data."
        }
    }