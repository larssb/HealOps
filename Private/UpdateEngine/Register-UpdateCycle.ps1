function Register-UpdateCycle() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    [Boolean] relative to the result of registering the update to a config file.
.NOTES
    General notes
.EXAMPLE
    Register-UpdateCycle -Config $Config
    Tries to register that an update cycle was run.
.PARAMETER Config
    The config file holding package management repository info. Of the PSCustomObject type
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The config file holding package management repository info. Of the PSCustomObject type.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config
    )

    #############
    # Execution #
    #############
    <#
        - An update cycle ran. Register it.
    #>
    # Determine DateTime for checkForUpdatesNext. Using a random plus "M" minutes, in order to NOT overload the Package Management backend with requests at the same time from multiple instances of HealOps. In this way update requests will be more evenly spread out.
    $checkForUpdatesNext_DateTimeRandom = get-random -Minimum 1 -Maximum 123
    if ($Config.checkForUpdatesInterval_InDays.length -ge 1) {
        # Use the interval from the HealOps config json file.
        $checkForUpdatesNext = (get-date).AddDays($Config.checkForUpdatesInterval_InDays).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
    } else {
        # Fall back to a default interval of 1 day. As the checkForUpdatesInterval_InDays property in the config file was corrupt.
        $checkForUpdatesNext = (get-date).AddDays(1).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
    }

    # When in verbose mode & for reference
    Write-Verbose -Message "The value of checkForUpdatesNext > $checkForUpdatesNext"
    $log4netLoggerDebug.debug("The value of checkForUpdatesNext > $checkForUpdatesNext")

    # Update the HealOps config json file
    $Config.checkForUpdatesNext = $checkForUpdatesNext

    # Convert the JSON
    $ConfigInJSON = ConvertTo-Json -InputObject $Config -Depth 3

    # Update the HealOps config json file
    try {
        Set-Content -Path "$PSScriptRoot/../../Artefacts/HealOpsConfig.json" -Value $ConfigInJSON -Force -Encoding UTF8 -ErrorAction Stop

        # Return
        $true
    } catch {
        # Log it
        $log4netLogger.error("Failed to write the HealOps config json file. Failed with > $_")

        # Return
        $false
    }
}