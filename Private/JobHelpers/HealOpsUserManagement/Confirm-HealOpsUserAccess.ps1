function Confirm-HealOpsUserAccess() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    [Boolean] relative to the result of controlling correct access for the local HealOps user.
.NOTES
    General notes
.EXAMPLE
    $accessConfirmation = Confirm-HealOpsUserAccess
    Calls Confirm-HealOpsUserAccess in order to verify if the HealOps user has the needed access.
.PARAMETER UserName
    The username of the HealOps user.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="The username of the HealOps user.")]
        [ValidateNotNullOrEmpty()]
        [String]$UserName = "HealOps"
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        if ($psVersionAbove4) {
            # Check if it is a member of the Administrators group
            $result = (Get-LocalGroupMember -SID S-1-5-32-544).Name -match $Username -as [Bool]
        } else {
            try {
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                [Boolean]$alreadyMember = ($AdministratorsGroup.Invoke("Members") | ForEach-Object { $_[0].GetType().InvokeMember("Name", 'GetProperty', $null,$_, $null) }).contains("$HealOpsUsername")
            } catch {
                $ErrorActionPreference = $currentErrorActionPreference

                throw ""
            }
        }
    }
    End {
        # Return
        $result
    }
}