function Set-PasswordOnLocalUser() {
<#
.DESCRIPTION
    Sets the password for the locally existing HealOps user.
.INPUTS
    [PSCustomObject] representing a local user. Either retrieved via the ADSI method or via cmdlets in the Microsoft.PowerShell.LocalAccounts module.
    A password. In either cleartext or as a Secure.String. Representing the password to set on the local HealOps user.
.OUTPUTS
    [Boolean] relative to the result of setting the password on the local user.
.NOTES
    <none>
.EXAMPLE
    $result = Set-PasswordOnLocalUser -User $User -Password $Password
    Explanation of what the example does
.PARAMETER User
    A local user object. Retrieved via either ADSI or cmdlets in the Microsoft.PowerShell.LocalAccounts module.
.PARAMETER Password
    The password to set on the local user.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword","")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A local user object. Retrieved via either ADSI or cmdlets in the Microsoft.PowerShell.LocalAccounts module.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$User,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The password to set on the local user.")]
        [ValidateNotNullOrEmpty()]
        $Password
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        if ($psVersionAbove4) {
            try {
                $User | Set-LocalUser -Password $Password -ErrorAction Stop
            } catch {
                throw "Set-PasswordOnLocalUser | Could not set the generated password on the already existing HealOps user. Failed with > $_"
            }
        } else {
            try {
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $User.SetPassword($Password)
                $User.SetInfo()
                $ErrorActionPreference = $currentErrorActionPreference
            } catch {
                throw "Set-PasswordOnLocalUser | Could not set the generated password on the already existing HealOps user. Failed with > $_"
            }
        }
    }
    End {
        # Return
        $true
    }
}