function Submit-ServiceStateReport() {
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
        [Parameter(Mandatory=$true, ParameterSetName="NAME", HelpMessage="MESSAGE")]
        [ValidateNotNullOrEmpty()]
        $suppe
    )

    #############
    # Execution #
    #############
}