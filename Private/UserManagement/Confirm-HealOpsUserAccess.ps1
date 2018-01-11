function Confirm-HealOpsUserAccess() {
<#
.DESCRIPTION
    Confirms that the locally existing user has the access it requires.
.INPUTS
    [String] representing the name of the HealOps user.
.OUTPUTS
    [Boolean] relative to the result of controlling correct access for the local HealOps user.
.NOTES
    <none>
.EXAMPLE
    $accessConfirmation = Confirm-HealOpsUserAccess
        > Calls Confirm-HealOpsUserAccess in order to verify if the HealOps user has the access it requires. In this example without the -UserName parameter used. As this parameter
        has a default value.
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
        # Check if the HealOps user is a member of the Administrators group
        if ($psVersionAbove4) {
            try {
                $result = (Get-LocalGroupMember -SID S-1-5-32-544 -ErrorAction Stop).Name -match $Username -as [Bool]
            } catch {
                throw "Verifying that the HealOps user has the correct access. Failed with > $_"
            }
        } else {
            try {
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "Stop"
                $ADSI = [ADSI]("WinNT://localhost")
                $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                [Boolean]$result = ($AdministratorsGroup.Invoke("Members") | ForEach-Object { $_[0].GetType().InvokeMember("Name", 'GetProperty', $null,$_, $null) }).contains("$UserName")
            } catch {
                throw "Verifying that the HealOps user has the correct access. Failed with > $_"
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