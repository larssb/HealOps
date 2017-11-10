function Update-TestRunningStatus() {
<#
.DESCRIPTION

.INPUTS
    <none>
.OUTPUTS
    [Boolean] corresponding to the result of updating the HealOps package config file.
.NOTES
    General notes
.EXAMPLE
    Update-TestRunningStatus -
    Explanation of what the example does
.PARAMETER HealOpsPackageConfigPath
    The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.
.PARAMETER TestFileName
    The name of the *.Tests.ps1 file.
.PARAMETER TestRunning
    Set this switch to indicate that the test is running.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.")]
        [ValidateNotNullOrEmpty()]
        [String]$HealOpsPackageConfigPath,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the *.Tests.ps1 file.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestFileName,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Set this switch to indicate that the test is running.")]
        [ValidateNotNullOrEmpty()]
        [Switch]$TestRunning
    )

    #############
    # Execution #
    #############
    # Use the global variable that contains the config of "X" HealOps package
    if ((Get-variable -Name HealOpsPackageConfig)) {
        # Define data for updating the status of a test
        $tempTestsCollection = @{}
        $tempTestsCollection.Add("name",$TestFileName)
        $tempTestsCollection.Add("running",$TestRunning)
        $tempTestsArray = @();

        # Start controlling the state of the test in question
        if ($null -eq $HealOpsPackageConfig.tests) {
            # Tests[] is not defined. Fix.
            Add-Member -InputObject $HealOpsPackageConfig -MemberType NoteProperty -Name "tests" -Value @()
            #$HealOpsPackageConfig.tests = $tempTestsArray
            $HealOpsPackageConfig.tests += $tempTestsCollection

            # Write the config file
            try {
                # Convert to JSON


                # Write
                Set-Content -Path $HealOpsPackageConfigPath -Value $HealOpsPackageConfig -Force -Encoding UTF8
            } catch {
                # Log it

                throw "Failed to write the HealOps package config file. Failed with > $_"
            }
        }

        if(-not ($HealOpsPackageConfig.tests.GetType().BaseType.Name) -eq "Array") {
            # Tests inside the HealOps package config is of the wrong datatype. Cannot trust it. Fix.
            $HealOpsPackageConfig.tests = $tempTestsArray
            $HealOpsPackageConfig.tests += $tempTestsCollection

            # Write the config file
            try {
                Set-Content -Path $HealOpsPackageConfigPath -Value $HealOpsPackageConfig -Force -Encoding UTF8
            } catch {
                # Log it

                throw "Failed to write the HealOps package config file. Failed with > $_"
            }
        }

        if($HealOpsPackageConfig.tests.name.Contains($TestFileName)) {
            # Update an already registered test
            $idxOfTheTest = $HealOpsPackageConfig.tests.name.IndexOf($TestFileName)
            $TestData = $HealOpsPackageConfig.tests[$idxOfTheTest]
            $TestData.Running = $TestRunning

            # Write the config file
            try {
                Set-Content -Path $HealOpsPackageConfigPath -Value $HealOpsPackageConfig -Force -Encoding UTF8
            } catch {
                # Log it

                throw "Failed to write the HealOps package config file. Failed with > $_"
            }
        } else {
            # The test has not already been registered. Register it.
            $HealOpsPackageConfig.tests += $tempTestsCollection

            # Write the config file
            try {
                Set-Content -Path $HealOpsPackageConfigPath -Value $HealOpsPackageConfig -Force -Encoding UTF8
            } catch {
                # Log it

                throw "Failed to write the HealOps package config file. Failed with > $_"
            }
        }
    } else {
        # Log it

        throw "The HealOpsPackageConfig variable is not defined. Cannot update the running status of the test."
    }
}