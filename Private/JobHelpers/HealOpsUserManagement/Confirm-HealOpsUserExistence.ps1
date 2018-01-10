function Confirm-HealOpsUserExistence() {
<#
.DESCRIPTION
    Simply confirms if the user, to use as the user for HealOps, exists locally.
.INPUTS
    Inputs (if any)
.OUTPUTS
    [PSCustomObject]
.NOTES
    Uses the HealOps global variable $psVersionAbove4
.EXAMPLE
    $result = Confirm-HealOpsUserExistence
        > Confirms if the user, to use as the user for HealOps, exists locally.
.PARAMETER UserName
    The username of the HealOps user.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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
        # Control if the user already exists
        if($psVersionAbove4) {
            $HealOpsUser = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
        } else {
            ####################
            # ADSI METHODOLOGY #
            ####################
            $ADSI = [ADSI]("WinNT://localhost")
            $currentErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "SilentlyContinue"
            $HealOpsUser = $ADSI.PSBase.Children.Find("$UserName")
            $ErrorActionPreference = $currentErrorActionPreference
        }
    }
    End {
        # Return
        $HealOpsUser
    }
}