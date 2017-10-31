#Requires -Module Pester, powershellTooling
function Invoke-HealOps() {
<#
.DESCRIPTION
    Invoke-HealOps is the function you call to initiate a HealOps package. Thereby testing "X" infrastructure.
    Where "X" could be n+m.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath
    )

    #############
    # Execution #
    #############
    Begin {

    }
    Process {
        if (Test-Path -Path $TestFilePath) {
            # Run the test
            $state = Test-EntityState -TestFilePath $TestFilePath

            # Did the test fail
            if ($state -eq $false) {
                Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                # Invoke repairs matching the failed test
                Repair-EntityState -TestFilePath $TestFilePath
            }
        } else {
            throw "The tests file $TestFilePath was not found.";
        }
    }
    End {}
}