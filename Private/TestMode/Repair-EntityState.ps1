function Repair-EntityState() {
<#
.DESCRIPTION
    Basically a wrapper function used to invoke a specific *.Repairs.ps1 file, companying a *.Tests.ps1 file.
.INPUTS
    [StringTestFilePath. Representing the path to the *.Tests.ps1 file that was executed and by which a failed state was identified.
    TestData. Holds data from executing the test/tests in the *.Tests.ps1 file.
.OUTPUTS
    [Boolean] relative to the result of the attempt to repair the state of "X" IT service/Entity
.NOTES
    <none>
.EXAMPLE
    PS C:\> $ResultOfRepair = Repair-EntityState -TestFilePath $TestsFile.FullName -TestData $testResult.testdata -ErrorAction Stop @commonParms
    Calls Repair-EntityState. The *.Repairs.ps1 file will be identified from the $TestsFile.FullName input and the TestData in the $TestResult.TestData will
    potentially be used by the *.Repairs.ps1 file, in order to repair a failed state of 'x' IT system/component.
.PARAMETER TestFilePath
    The full path to a *.Tests.ps1 file. From this file the Repairs file will be determined.
.PARAMETER TestData
    Data from an executed test.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Boolean])]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$TestFilePath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $TestData
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        # Define the filename of the Repairs file.
        $RepairsFile = $TestFilePath -replace "Tests.ps1","Repairs.ps1"
        Write-Verbose -Message "Repair-EntityState | The repairs file was resolved to: $RepairsFile"
        $log4netLoggerDebug.debug("Repair-EntityState | The repairs file was resolved to: $RepairsFile")

        if (Test-Path -Path $RepairsFile) {
            # Run the repair
            try {
                if ($PSBoundParameters.ContainsKey('Verbose')) {
                    $RepairResult = . $RepairsFile -TestData $TestData -Verbose
                } else {
                    $RepairResult = . $RepairsFile -TestData $TestData
                }
            } catch {
                throw "Repair-EntityState | Running the repairs in the following repairs file > $RepairsFile failed with > $_"
            }
            $log4netLoggerDebug.debug("Repair-EntityState | The result of the repair is: $RepairResult")
            Write-Verbose -Message "Repair-EntityState | The result of the repair is: $RepairResult"
        } else {
            $log4netLogger.error("Repair-EntityState | The repairs file $RepairsFile could not be found.")
            throw "Repair-EntityState | The repairs file $RepairsFile could not be found.";
        }
    }
    End {
        # Return - Report on the success of repairing the IT Service/Entity.
        if($RepairResult -eq $true) {
            $true
        } else {
            $false
        }
    }
} # End of the Repair-EntityState function.