##Requires -

function New-HealOpsTask() {
<#
.DESCRIPTION
    New-HealOpsTask is used to create either:
        a) a "Scheduled Taks" if OS == Windows or
        b) a "cron" job if OS == Linux or MacOS
.INPUTS
    Inputs (if any)
.OUTPUTS
    [Boolean]
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
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to name the task.")]
        [ValidateNotNullOrEmpty()]
        $name
    )

    #############
    # Execution #
    #############
}