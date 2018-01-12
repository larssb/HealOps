function Get-TestsFileJobInterval() {
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
    Parameter_HelpMessage_text
    Add_a_PARAMETER_per_parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([SPECIFY_THE_RETURN_TYPE_OF_THE_FUNCTION_HERE])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="NAME", HelpMessage="MESSAGE")]
        [ValidateNotNullOrEmpty()]
        $NAMEOFPARAMETER
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {

    }
    End {}
}