##Requires -
function Register-UpdateCheck() {
<#
.DESCRIPTION
    Intern HealOps function that registers a dateTime object in the HealOpsConfig json file. Which is used as part of the checkForUpdates functionality of HealOps.
.INPUTS
    <none>
.OUTPUTS
    [Boolean] relative to the result of storing the dateTime of a processed update check, to the HealOps config json file.
.NOTES
    Uses the global variable $healOpsConfig. Setup in the invoke-healops function.
.EXAMPLE
    Register-UpdateCheck -
    Explanation of what the example does
.PARAMETER dateTime
    Parameter_HelpMessage_text
    Add_a_PARAMETER_per_parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The ")]
        [ValidateNotNullOrEmpty()]
        [date]$dateTime
    )

    #############
    # Execution #
    #############

}