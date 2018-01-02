function Get-LatestModuleVersionLocally() {
    <#
    .DESCRIPTION
        Returns the latest version of a locally installed PowerShell module.
    .INPUTS
        <none>
    .OUTPUTS
        [PSModuleInfo] representing the latest version of the locally installed module.
    .NOTES
        <none>
    .EXAMPLE
        Get-LatestModuleVersionLocally -ModuleName Citrix.HealOpsPackage
        Returns the latest version of a locally installed Citrix.HealOpsPackage PowerShell module.
    .PARAMETER ModuleName
        The name of the module.
    #>

    # Define parameters
    [CmdletBinding()]
    [OutputType([PSModuleInfo])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the module.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName
    )

    #############
    # Execution #
    #############
    # Get the module
    try {
        $module = Get-Module -ListAvailable $ModuleName -ErrorAction Stop
    } catch {
        throw "Get-LatestModuleVersionLocally > No module named $ModuleName could be found."
    }

    # Get the latest version installed locally of the $ModuleName
    try {
        $Latest = ($module | Sort-Object -Property Version -Descending -ErrorAction Stop)[0]
    } catch {
        throw "Get-LatestModuleVersionLocally > Determining the latest version of the module named $ModuleName failed with > $_"
    }

    # Return
    $Latest
}