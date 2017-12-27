function Get-ExtractModulePath() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    [String] representing the path to extract the module being updated or installed.
.NOTES
    General notes
.EXAMPLE
    Get-ExtractModulePath -
    Explanation of what the example does
.PARAMETER NAME_OF_THE_PARAMETER_WITHOUT_THE_QUOTES
    Parameter_HelpMessage_text
    Add_a_PARAMETER_per_parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="NAME", HelpMessage="MESSAGE")]
        [ValidateNotNullOrEmpty()]
        $NAMEOFPARAMETER
    )

    #############
    # Execution #
    #############
    # Define the path to extract to
    if($psVersionAbove4) {
        $extractModulePath = "$ProgramFilesModulesPath/$modulename/$Version"
    } else {
        # No version value in the path def.
        $extractModulePath = "$ProgramFilesModulesPath/$modulename"

        # Remove the module folder if it is already present - PS v4 and below
        if(-not $psVersionAbove4) {
            if(Test-Path -Path $extractModulePath) {
                try {
                    Remove-Item -Path $extractModulePath -Force -Recurse -ErrorAction Stop
                } catch {
                    Write-Output "Cannot continue...."
                    throw "Failed to remove the already existing module folder, for the module named $ModuleName (prep. for installing the module on a system with a PowerShell version `
                    that do not support module versioning). It failed with > $_"
                }
            }
        }
    }

    # Return
    [String]$extractModulePath
}