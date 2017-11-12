function Test-RunningTest() {
<#
.DESCRIPTION

.INPUTS
    <none>
.OUTPUTS
    [Boolean] corresponding to the result of testing if "X" test is already running.
.NOTES
    General notes
.EXAMPLE
    Test-RunningTest -TestFileName $TestFileName
    Parses the global variable named HealOpsPackageConfig (set inside Invoke-HealOps) to determine if "X" test is already running.
.PARAMETER TestFileName
    The name of the *.Tests.ps1 file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the *.Tests.ps1 file.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestFileName
    )

    #############
    # Execution #
    #############
    # Use the global variable that contains the config of "X" HealOps package
    if ((Get-variable -Name HealOpsPackageConfig -ErrorAction SilentlyContinue)) {
        # Start controlling the state of the test in question
        if ($null -eq $HealOpsPackageConfig.tests) {
            # No tests are running at all, as the HealOps package config has not been written to
            $false
            Write-Verbose -Message "The Tests[] is not defined in the HealOpsPackageConfig variable."
        } else {
            # See if the test in question is in the Tests[]
            $testRegistered = $HealOpsPackageConfig.tests.name.Contains($TestFileName)
            if ($testRegistered) {
                Write-Verbose -Message "The test was found in Tests[]."
                # Determine if the test is running or not
                $idxOfTheTest = $HealOpsPackageConfig.tests.name.IndexOf($TestFileName)
                $TestData = $HealOpsPackageConfig.tests[$idxOfTheTest]
                if ($TestData.Running -as [Boolean] -eq $true) {
                    # The test is running
                    $true
                } else {
                    $false
                }
            } else {
                # The test has not been registered it can be started
                $false
                Write-Verbose -Message "The test was NOT found in Tests[]."
            }
        }
    } else {
        # Log it

        throw "The HealOpsPackageConfig variable is not defined. Cannot continue."
    }
}