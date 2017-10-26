function Repair-EntityState() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    Outputs (if any)
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER NAME_OF_THE_PARAMETER_WITHOUT_THE_QUOTES
    Parameter HelpMessage text
    Add a .PARAMETER per parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([SPECIFY_THE_RETURN_TYPE_OF_THE_FUNCTION_HERE])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The ID of the repair to run on an IT Service/Entity that is in a faild state.")]
        [ValidateNotNullOrEmpty()]
        [int]$Repair,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.
        From this file the Repairs file will be found.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath

    )

    #############
    # Execution #
    #############

    # Define the filename of the Repairs file.
    # TODO: If JSON do the necessary
    $repairsFile = $TestFilePath -replace "Tests","Repairs"

    if (Test-Path -Path $repairsFile) {
        # Get the content of the test matching the ID in the JSON file

        # Run the repair

        # Report on the success of repairing the IT Service/Entity
        if($repairSuccess -eq $true) {
            # Report that it was repaired
            Submit-ServiceStateReport -Status -Service
        } else {
            # Alarm on-call personnel

        }

    } else {
        throw "The repairs file does not exist > $_";
    }
}