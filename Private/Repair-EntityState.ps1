function Repair-EntityState() {
<#
.DESCRIPTION
    Wrapper function used to invoke a specific *.Repairs.ps1 file for a failed test.
.INPUTS
    <none>
.OUTPUTS
    <none>
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
    # TODO: If JSON do the necessary
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
            # Report that it was repaired
            #Submit-EntityStateReport -Status -Service

        } else {
            # Alarm on-call personnel
            #Ping-Personnel -entityName $

            # Report that the personnel was contacted
            # Submit-EntityStateReport
        }
    } else {
        throw "The repairs file $repairsFile could not be found.";
    }
}