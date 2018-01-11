function Resolve-HealOpsUserRequirement() {
<#
.DESCRIPTION
    The function confirms that the HealOps user on the local system is available and working. It does this by:
        > Confirming that the user exists
        > That it has the correct access rights on the local system.
.INPUTS
    [String] one each for a UserName and Password on the user.
.OUTPUTS
    [Boolean] relative to the result of confirming that the HealOps user on the local system is fully working.
.NOTES
    <none>
.EXAMPLE
    [Bool]$result = Resolve-HealOpsUserRequirement -Password $Password -UserName $UserName
        > Calls Resolve-HealOpsUserRequirement with the parameters needed for verifying that the requires HealOps user is available and correctly configured locally.
.PARAMETER Password
    The password to set on the local user.
.PARAMETER UserName
    The username of the HealOps user.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword","")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The password to set on the local user.")]
        [ValidateNotNullOrEmpty()]
        [String]$Password,
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
        [bool]$result = $false # Semaphore
    }
    Process {
        $HealOpsUser = Confirm-HealOpsUserExistence
        if ($null -eq $HealOpsUser) {
            # The user for HealOps does not already exist. Create it
            try {
                [Bool]$result = New-HealOpsUser -Password $Password
            } catch {
                throw $_
            }
        } else {
            # Set the password on the already existing HealOps user
            try {
                $result = Set-PasswordOnLocalUser -Password $Password -User $HealOpsUser
            } catch {
                throw $_
            }

            # Confirm and set access permissions on the user
            if ($result) {
                try {
                    $result = Confirm-HealOpsUserAccess
                } catch {
                    throw $_
                }

                # The user is not a member of the local 'Administrators' group. Add it.
                if (-not $result) {
                    $result = Set-HealOpsUserAccess
                }
            }
        }
    }
    End {
        # Return
        $result
    }
}