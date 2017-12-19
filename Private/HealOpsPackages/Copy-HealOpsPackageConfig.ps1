function Copy-HealOpsPackageConfig() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    Outputs (if any)
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER HealOpsPackageConfig
    The HealOpsPackage config. Of the PSCustomObject type.
.PARAMETER
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The HealOpsPackage config. Of the PSCustomObject type.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$HealOpsPackageConfig,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The path to the module root of the HealOps package to copy the config file for.")]
        [ValidateNotNullOrEmpty()]
        [String]$HealOpsPackageModuleRoot,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The new version of an updated HealOps package.")]
        [ValidateNotNullOrEmpty()]
        [String]$NewVersion,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the HealOps package.")]
        [ValidateNotNullOrEmpty()]
        [String]$HealOpsPackageName

    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        # Convert the JSON
        $ConfigInJSON = ConvertTo-Json -InputObject $HealOpsPackageConfig -Depth 3

        # Copy the HealOps package config json file
        try {
            Set-Content -Path "$HealOpsPackageModuleRoot/$NewVersion/Config/$HealOpsPackageName.json" -Value $ConfigInJSON -Force -Encoding UTF8 -ErrorAction Stop
        } catch {
            # Log it
            $log4netLogger.error("Failed to copy the config json file for the HealOps package named > $HealOpsPackageName. It failed with > $_")
        }
    }
    End {}
}