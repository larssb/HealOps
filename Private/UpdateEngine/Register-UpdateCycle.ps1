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

    # When in verbose mode & for reference
    Write-Verbose -Message "The value of checkForUpdatesNext > $checkForUpdatesNext"
    $log4netLoggerDebug.debug("Register-UpdateCycle > The value of checkForUpdatesNext > $checkForUpdatesNext")

    # Update the HealOps config json file
    $Config.checkForUpdatesNext = $checkForUpdatesNext

    # Convert the JSON
    $ConfigInJSON = ConvertTo-Json -InputObject $Config -Depth 3

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