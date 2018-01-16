function Register-UpdateCycle() {
    <#
    .DESCRIPTION
        Registers the fact that an HealOps update cycle ran.
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        [Boolean] relative to the result of registering the update to a config file.
    .NOTES
        <none>
    .EXAMPLE
        Register-UpdateCycle -Config $Config -ModuleBase $MainModule.ModuleBase
        Tries to register that an update cycle was run.
    .PARAMETER Config
        The config file holding package management repository info. Of the PSCustomObject type
    .PARAMETER ModuleBase
        The base (folder path) to the location of the updated module.
    #>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The config file holding package management repository info. Of the PSCustomObject type.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The base (folder path) to the location of the updated module.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleBase
    )

    #############
    # Execution #
    #############
    <#
        - An update cycle ran. Register it.
    #>
    # Determine DateTime for checkForUpdatesNext. Using a random plus "M" minutes, in order to NOT overload the Package Management backend with requests at the same time from multiple instances of HealOps. In this way update requests will be more evenly spread out.
    $checkForUpdatesNext_DateTimeRandom = get-random -Minimum 1 -Maximum 123
    if ($Config.checkForUpdatesInterval_Hours.length -ge 1) {
        # Use the interval from the HealOps config json file.
        $checkForUpdatesNext = (get-date).AddHours($Config.checkForUpdatesInterval_Hours).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
    } else {
        # Fall back to a default interval of 1 day. As the checkForUpdatesInterval_Hours property in the config file was corrupt.
        $checkForUpdatesNext = (get-date).AddHours(1).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
    }

    <#
        - Compare HealOps configs. The current and the one from the update.
            > In order to catch changes and reflect them to the HealOps config file that will be used going forward.
    #>
    # Get the config from the update
    [PSModuleInfo]$MainModule = Get-LatestModuleVersionLocally -ModuleName "HealOps"
    [System.Array]$updatedHealOpsConfig = Get-HealOpsConfig -ModuleBase $MainModule.ModuleBase
    [Array]$configComparisonResult = Compare-HealOpsConfig -currentConfig $Config -updatedConfig $updatedHealOpsConfig

    # Determine the config file to use as the one going forward
    if ($configComparisonResult.Count -ge 1) {
        # Differences was found. Reflect them.
        try {
            [PSCustombObject]$syncedConfig = Sync-HealOpsConfig -configChanges $configComparisonResult -currentConfig $Config
            $syncFailed = $false
        } catch {
            $log4netLogger.error("$_")
            $syncFailed = $true
        }
    } else {
        # No changes found. Debug log.
        $log4netLoggerDebug.Debug("There was no changes found when comparing the current HealOps config and the updated one. All good in the hood.`
        Count on the compare $($configComparisonResult.Count)")
    }

    if (-not $syncFailed) {
        # The sync succeeded. Use the synced config object.
        [PSCustombObject]$configToUse = $syncedConfig
    } else {
        # The sync failed. Use the non-updated current config object. Falling back to this as the chance of this working is higher that a non-properly updated config object. At least that is the assumption
        [PSCustombObject]$configToUse = $Config
    }

    # When in verbose mode & for reference
    Write-Verbose -Message "The value of checkForUpdatesNext > $checkForUpdatesNext"
    $log4netLoggerDebug.debug("Register-UpdateCycle > The value of checkForUpdatesNext > $checkForUpdatesNext")

    # Update the HealOps config json file
    $configToUse.checkForUpdatesNext = $checkForUpdatesNext

    # Convert the JSON
    $ConfigInJSON = ConvertTo-Json -InputObject $configToUse -Depth 3

    # Update the HealOps config json file
    try {
        # Record the update cycle data to the HealOps modules config file.
        Set-Content -Path "$ModuleBase/Artefacts/HealOpsConfig.json" -Value $ConfigInJSON -Force -Encoding UTF8 -ErrorAction Stop

        # Return
        $true
    } catch {
        # Log it
        $log4netLogger.error("Register-UpdateCycle > Failed to write the config json file for the module > $ModuleBase. Failed with > $_")

        # Return
        $false
    }
}