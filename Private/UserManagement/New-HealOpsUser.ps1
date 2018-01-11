function New-HealOpsUser() {
<#
.DESCRIPTION
    Creates a local user for HealOps to use when invoking jobs that executes *.Tests.ps1 scripts.
.INPUTS
    [String] representing the password to set on the local user.
    [String] representing the username to give the HealOps user to be created.
.OUTPUTS
    [Boolean] relative to the result of creating a local HealOps user.
.NOTES
    <none>
.EXAMPLE
    New-HealOpsUser
        > Creates a local user for HealOps to use when invoking jobs that executes *.Tests.ps1 scripts.
.PARAMETER Password
    The password to set on the local user.
.PARAMETER UserDescription
    Used to execute HealOps tests & repairs files.
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
        [String]$UserDescription = "Used to execute HealOps tests & repairs files.",
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
            try {
                $HealOpsUser = New-LocalUser -Name $UserName -AccountNeverExpires -Description $UserDescription -Password $password -PasswordNeverExpires -UserMayNotChangePassword
            } catch {
                throw "Failed to create a batch user for HealOps. The error was > $_"
            }

            # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
            try {
                Add-LocalGroupMember -SID S-1-5-32-544 -Member $HealOpsUser
            } catch {
                throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
            }
        } else {
            $currentErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Stop"
            try {
                $ADSI = [ADSI]("WinNT://localhost")
                $HealOpsUser = $ADSI.Create('User', "$UserName");
                $HealOpsUser.SetPassword($password)
                $HealOpsUser.SetInfo()
                $HealOpsUser.Description = "$UserDescription"
                $HealOpsUser.SetInfo()
                $HealOpsUser.UserFlags = 66145 # Sets: 'User cannot change password' and 'Password never expires'
                $HealOpsUser.SetInfo()
            } catch {
                $ErrorActionPreference = $currentErrorActionPreference
                throw "Failed to create a batch user for HealOps. The error was > $_"
            } finally {
                if ($null -ne $HealOpsUser) {
                    $HealOpsUser.Close()
                }
            }

            # Add the user to the 'Administrators' group.
            try {
                $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                $AdministratorsGroup.invoke("Add", "WinNT://$env:COMPUTERNAME/$UserName,user")
            } catch {
                $ErrorActionPreference = $currentErrorActionPreference
                throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
            } finally {
                if ($null -ne $AdministratorsGroup) {
                    $AdministratorsGroup.Close()
                }
            }
        }
    }
    End {
        # Return
        $true
    }
}