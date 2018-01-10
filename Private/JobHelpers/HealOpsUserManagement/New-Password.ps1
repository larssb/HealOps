function New-Password() {
<#
.DESCRIPTION
    Generates a password to be used on the HealOps user.
.INPUTS
    <none>
.OUTPUTS
    [String] representing either a secure string type password or a cleartext password.
.NOTES
    <none>
.EXAMPLE
    $password = New-Password -PasswordType "ClearText"
        > Generates a password to be used on the HealOps user.
.PARAMETER PasswordType
    Used to specify if the password object returned should be cleartext or a secure string.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify if the password object returned should be cleartext or a secure string.")]
        [ValidateSet('ClearText', 'SecureString')]
        [String]$PasswordType
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        # Password for the local user
        $numbers = 1..100
        $randomNumbers = Get-Random -InputObject $numbers -Count 9
        $chars = [char[]](0..255) -clike '[A-z]'
        $randomChars = Get-Random -InputObject $chars -Count 9
        $charsAndNumbers = $randomNumbers
        $charsAndNumbers += $randomChars
        $charsAndNumbersShuffled = $charsAndNumbers | Sort-Object {Get-Random}

        # Define the password
        if ($PasswordType -eq "SecureString") {
            $password = ConvertTo-SecureString -String ($charsAndNumbersShuffled -join "") -AsPlainText -Force
        } else {
            $password = ($charsAndNumbersShuffled -join "")
        }
    }
    End {
        # Return
        $password
    }
}