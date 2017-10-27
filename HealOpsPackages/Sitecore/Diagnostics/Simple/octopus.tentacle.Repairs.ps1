<#function Repair-octopusTentacle() {
#
.DESCRIPTION
    Remediates the failure of the Octopus deploy tentacle client.
.INPUTS
    Repair  of the remediating code to execute.
.OUTPUTS
    [Boolean] on the status of the remediation.
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
#.#PARAMETER Repair
    The ID of the repair to run on an IT Service/Entity that is in a faild state.
#

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        #[Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The ID of the repair to run on an IT Service/Entity that is in a faild state.")]
        [ValidateNotNullOrEmpty()]
        [int]$Repair
        #
    )

    #############
    # Execution #
    #############

    Write-Verbose -Message "Hello freaking world!"

    $true

}
#>

Write-Verbose -Message "Hello freaking world!"

    $true