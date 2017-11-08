function Invoke-HealOps() {
<#
.DESCRIPTION
    Invoke-HealOps is the function you call to initiate a HealOps package. Thereby testing "X" IT service/Entity.
    Where "X" could be n+m.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    Invoke-HealOps -TestFilePath $TestFilePath -
    Explanation of what the example does
.PARAMETER TestFilePath
    A file containing the tests to run. This should be the full-path to the *.Tests.ps1 file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$HealOpsPackageConfigPath
    )

    #############
    # Execution #
    #############
    Begin {
        # Get the HealOps config file
        $healOpsConfig = Get-Content -Path $PSScriptRoot/../Artefacts/HealOpsConfig.json -Encoding UTF8 | ConvertFrom-Json

        # Get the HealOps package config file. A JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.

        <#
            - Should be "somewhere" in the specific HealOpsPackage folder
            - We will just go look for it....
            - Document this in the ReadMe....
        #>
        $HealOpsPackageConfig = Get-Content -Path $TestFilePath -Encoding UTF8 | ConvertFrom-Json
    }
    Process {
        if (Test-Path -Path $TestFilePath) {
            # Run the test
            $testResult = Test-EntityState -TestFilePath $TestFilePath

            if ($testResult.state -eq $false) {
                ####
                # The test failed
                ####
                Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                # Invoke repairs matching the failed test
                $resultOfRepair = Repair-EntityState -TestFilePath $TestFilePath -TestData $testResult.testdata

                if ($resultOfRepair -eq $false) {
                    # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -tagpairs $($testResult.tags) -metricValue $($testResult.testdata.FailureMessage)
                    } catch {
                        Write-Verbose "Submit-EntityStateReport failed with: $_"

                        # TODO: LOG IT and inform x
                    }
                } else {
                    # Run the *.Tests.ps1 file again to verify and get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.

                    # THINK THIS THROUGH!
                }
            } else {
                ####
                # The test succeeded
                ####
                if ((Get-Variable -Name assertionResult)) {
                    # Report the state of the service to the backend report system.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -tagpairs $($testResult.tags) -metricValue $assertionResult
                    } catch {
                        Write-Verbose "Submit-EntityStateReport failed with: $_"

                        # TODO: LOG IT and inform x
                    }
                } else {
                    # TODO: Log IT and inform x!
                    Write-Verbose -Message "The assertionResult variable was not defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                }
            }
        } else {
            throw "The tests file $TestFilePath was not found."

            # TODO: Somebody needs to know.
        }
    }
    End {}
}