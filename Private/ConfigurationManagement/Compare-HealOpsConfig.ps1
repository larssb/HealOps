function Compare-HealOpsConfig() {
<#
.DESCRIPTION
    Compares the current HealOps config file with the one in an updated version of HealOps. In order to find the properties that might have been changed or added.
.INPUTS
    [PSCustomObject] one for each HealOps config file.
.OUTPUTS
    [System.Array] Representing the changes, if any, between the current and the updated HealOps config file.
.NOTES
    - It is assumed that the reference object (the correct) is the HealOps config from an updated version of HealOps. The thinking being > this is what is updated so that is the master.
.EXAMPLE
    [Array]$configCompare = Compare-HealOpsConfig -currentConfig $currentHealOpsConfig -updatedConfig $updatedHealOpsConfig
        > Compares the current and the updated HealOps config files and returns the result.
.PARAMETER CurrentConfig
    The current HealOps config file. To be compared with the HealOps config file coming in from an updated version of HealOps.
.PARAMETER UpdatedConfig
    The updated HealOps config file. To be compared with the current HealOps config file
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$CurrentConfig,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$UpdatedConfig
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        try {
            $Result = Compare-Object -ReferenceObject $UpdatedConfig.psobject.Properties.name -DifferenceObject $CurrentConfig.psobject.Properties.name -PassThru -ErrorAction Stop
        } catch {
            $log4netLogger.error("Failed to compare the two HealOps config files. Failed with > $_")
        }

        if($null -ne $result -and $result.Count -ge 1) {
            try {
                $result = $result | Where-Object { $_.SideIndicator -eq "<=" } -ErrorAction Stop
            } catch {
                $log4netLogger.error("Failed to filter on sideIndicator. Failed with > $_")
                Write-Verbose -Message "Failed to filter on sideIndicator. Failed with > $_"
            }
        } else {
            # Return empty list.....you know > to be nice
            $Result = @()

            $log4netLoggerDebug.debug("The config comparison returned no changes between the config files.")
            Write-Verbose -Message "The config comparison returned no changes between the config files."
        }
    }
    End {
        # Return - The comma is to stop PowerShell from unrolling the collection. As we really do want to potentially return an empty collection if no changes was found in the comparison.
        ,$Result
    }
}