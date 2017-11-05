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
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.
        From this file the Repairs file will be found.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Data from an executed test.")]
        [ValidateNotNullOrEmpty()]
        $TestData
    )

    #############
    # Execution #
    #############

    # Define the filename of the Repairs file.
    $repairsFile = $TestFilePath -replace "Tests","Repairs"
    Write-Verbose -Message "The repairs file was resolved to: $repairsFile"

    if (Test-Path -Path $repairsFile) {
        # Run the repair
        if ($PSBoundParameters.ContainsKey('Verbose')) {
            $repairResult = . $repairsFile -TestData $TestData -Verbose
        } else {
            $repairResult = . $repairsFile -TestData $TestData
        }
        Write-Verbose -Message "The result of the repair is: $repairResult"

        # Report on the success of repairing the IT Service/Entity
        if($repairResult -eq $true) {
            # Return
            $true
        } else {
            # Return
            $false
        }
    } else {
        # TODO report it, log it == HARDEN
        throw "The repairs file $repairsFile could not be found.";
    }
}