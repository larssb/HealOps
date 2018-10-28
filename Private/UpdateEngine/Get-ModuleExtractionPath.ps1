function Get-ModuleExtractionPath() {
    <#
    .DESCRIPTION
        Determines the path to extract a module to. A module downloaded from a package management backend.
    .INPUTS
        <none>
    .OUTPUTS
        [String] representing the path to extract the module being updated or installed.
    .NOTES
        Uses the global variable named psVersionAbove4 which is set in the Invoke-HealOps function.
    .EXAMPLE
        $extractModulePath = Get-ModuleExtractionPath -ModuleName $ModuleName
        > Determines the path to extract a module to. A module downloaded from a package management backend.
    .PARAMETER ModuleName
        The name of the module being installed or updated.
    .PARAMETER Version
        The version of the module being installed or updated.
    #>

    # Define parameters
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the module being installed or updated.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The version of the module being installed or updated.")]
        [ValidateNotNullOrEmpty()]
        [String]$Version
    )

    #############
    # Execution #
    #############
    Begin {
        # Determine the systems PowerShell Program Files Module path.
        $PSModulesPath = Get-PSModulesPath
    }
    Process {
        # Define the path to extract to
        if($psVersionAbove4) {
            # Version in the extract path def.
            $extractModulePath = "$PSModulesPath/$modulename/$Version"
        } else {
            # No version value in the path def.
            $extractModulePath = "$PSModulesPath/HealOps/Artefacts/Temp"
        }
    }
    End {
        # Return
        [String]$extractModulePath
    }
}