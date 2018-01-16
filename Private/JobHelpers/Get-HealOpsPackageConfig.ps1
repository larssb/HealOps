function Get-HealOpsPackageConfig() {
<#
.DESCRIPTION
    Returns the config file of a HealOps package.
.INPUTS
    [String] representing the ModuleBase path of a HealOps package.
.OUTPUTS
    [System.Array] representing the config file of the HealOps package. Converted from JSON.
.NOTES
    Uses the global variable named $psVersionAbove4.
.EXAMPLE
    $HealOpsPackageConfig = Get-HealOpsPackageConfig -ModuleBase $Package.ModuleBase
        > Returns the config JSON file of the HealOps package in $Package.
.PARAMETER ModuleBase
    The base path of the HealOps package PowerShell module.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The base path of the HealOps package PowerShell module.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleBase
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        try {
            if($psVersionAbove4) {
                [Array]$HealOpsPackageConfig = Get-Content -Path $ModuleBase/Config/*.json -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            } else {
                [Array]$HealOpsPackageConfig = Get-Content -Path $ModuleBase/Config/*.json -ErrorAction Stop | out-string -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            }
        } catch {
            $log4netLogger.error("Get-HealOpsPackageConfig > Getting the config file failed with > $_")
        }

        # Control that HealOpsPackageConfig contains elements
        if (-not $HealOpsPackageConfig.Count -ge 1) {
            # Return empty list.....you know > to be nice
            [Array]$HealOpsPackageConfig = @()
        }
    }
    End {
        # Return
        ,$HealOpsPackageConfig
    }
}