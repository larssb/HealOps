function Resolve-HealOpsUserRequirement() {
<#
.DESCRIPTION
    The function confirms that the HealOps user on the local system is available and working. It does this by:
        >
        >
.INPUTS
    Inputs (if any)
.OUTPUTS
    [Boolean] relative to the result of confirming that the HealOps user on the local system is fully working.
.NOTES
    <none>
.EXAMPLE
    Resolve-HealOpsUserRequirement
    Explanation of what the example does
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
    Begin {
        <#
            - Shared script scope variables
        #>

    }
    Process {
        $HealOpsUser = Confirm-HealOpsUserExistence -ErrorAction Stop
        if ($null -eq $HealOpsUser) {
            # The user for HealOps does not already exist. Create it
            [Bool]$createHealOpsUserResult = New-HealOpsUser


        } else {
            # Set the password on the already existing HealOps user
            try {
                $result = Set-PasswordOnLocalUser -Password $password -User $HealOpsUser
            } catch {
                throw $_ # throw to higher hierarchy function. Will be the Install-HealOpsPackage().
            }

            # Confirm and set access permissions on the user
            $accessConfirmation = Confirm-HealOpsUserAccess

            if (-not $accessConfirmation) {
                # Add the user to the local administrators group
                Set-HealOpsUserAccess -
            }
        }
    }
    End {
        # Clean-up
        ### Password variables....relative to version of PS
    }
}



                    # Clean-up
                    # To release resources used via ADSI.
                    $currentErrorActionPreference = $ErrorActionPreference
                    $ErrorActionPreference = "SilentlyContinue"
                    #$HealOpsUser.Close()
                    #$AdministratorsGroup.Close()
                    $ErrorActionPreference = $currentErrorActionPreference