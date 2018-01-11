function Set-HealOpsUserAccess() {
<#
.DESCRIPTION
    Ensures that the local HealOps user has the access it requires.
        > Membership of the local 'Administrators' group.
.INPUTS
    [String] representing the UserName of the local HealOps user.
.OUTPUTS
    [Bool] relative to the result of adding the HealOps user to the local systems 'Administrators' group.
.NOTES
    <none>
.EXAMPLE
    $result = Set-HealOpsUserAccess -UserName $UserName
        > Adds the user named in $UserName to the local 'Administrators' group.
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
            - Shared variables
        #>
        $result = $false # Semaphore
    }
    Process {
        # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
        if($psVersionAbove4) {
            try {
                Add-LocalGroupMember -SID S-1-5-32-544 -Member $UserName
                $result = $true
            } catch {
                throw "Failed to add the $UserName batch user to the local 'Administrators' group. The error was > $_"
            }
        } else {
            try {
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $ADSI = [ADSI]("WinNT://localhost")
                $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                $AdministratorsGroup.invoke("Add", "WinNT://$env:COMPUTERNAME/$UserName,user")
                $result = $true
            } catch {
                throw "Failed to add the $UserName batch user to the local 'Administrators' group. The error was > $_"
            } finally {
                $ErrorActionPreference = $currentErrorActionPreference
                $AdministratorsGroup.Close()
            }
        }
    }
    End {
        # Return
        $result
    }
}