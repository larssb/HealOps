function Repair-EntityState() {
<#
.DESCRIPTION
    Wrapper function used to invoke a specific *.Repairs.ps1 file for a failed test.
.INPUTS
    <none>
.OUTPUTS
    [Boolean] relative to the result of the attempt to repair the state of "X" IT service/Entity
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file. From this file the Repairs file will be found.
.PARAMETER TestData
    Data from an executed test.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $TestData
    )

    #############
    # Execution #
    #############

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

        # Report on the success of repairing the IT Service/Entity
        if($RepairResult -eq $true) {
            # Return
            $true
        } else {
            # Return
            $false
        }
    } else {
        # TODO report it, log it == HARDEN
        $log4netLogger.error("Repair-EntityState | The repairs file $RepairsFile could not be found.")
        throw "Repair-EntityState | The repairs file $RepairsFile could not be found.";
    }
}