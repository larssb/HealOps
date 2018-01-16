function Get-HealOpsConfig() {
    <#
    .DESCRIPTION
        Returns the config file of 'X' version of HealOps.
    .INPUTS
        [String] representing the ModuleBase path of a version of the HealOps module.
    .OUTPUTS
        [System.Array] represents the config file of a version of the HealOps module. Converted from JSON.
    .NOTES
        Uses the global variable named $psVersionAbove4.
    .EXAMPLE
        $HealOpsConfig = Get-HealOpsConfig -ModuleBase $Package.ModuleBase
            > Returns the config JSON file, relative to the version of HealOps, pointed to via the -ModuleBase parameter.
    .PARAMETER ModuleBase
        The base path of the version of HealOps to retrieve the HealOps config file from.
    #>

        # Define parameters
        [CmdletBinding()]
        [OutputType([System.Array])]
        param(
            [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The base path of the version of HealOps to retrieve the HealOps config file from.")]
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
                    [Array]$HealOpsConfig = Get-Content -Path $ModuleBase/Artefacts/*.json -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                } else {
                    [Array]$HealOpsConfig = Get-Content -Path $ModuleBase/Artefacts/*.json -ErrorAction Stop | out-string -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                }
            } catch {
                $log4netLogger.error("Get-HealOpsConfig > Getting the config file failed with > $_")
            }

            # Control that HealOpsConfig contains elements
            if (-not $HealOpsConfig.Count -ge 1) {
                # Return empty list.....you know > to be nice
                [Array]$HealOpsConfig = @()
            }
        }
        End {
            # Return
            ,$HealOpsConfig
        }
    }