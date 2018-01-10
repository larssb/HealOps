function Set-HealOpsUserAccess() {
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
        if($psVersionAbove4) {

            if ($matchOrNot -eq $false) {
                # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
                try {
                    Add-LocalGroupMember -SID S-1-5-32-544 -Member $HealOpsUser
                } catch {
                    throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
                }
            }
        } else {

            try {
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $AdministratorsGroup.invoke("Add", "WinNT://$env:COMPUTERNAME/$HealOpsUsername,user")
            } catch {
                throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
            } finally {

            }
        }
    }
    End {}
}