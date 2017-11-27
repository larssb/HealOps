function Confirm-TimeToUpdate() {
<#
.DESCRIPTION
    Confirms if an update cycle should run or not.
.INPUTS
    <none>
.OUTPUTS
    [Boolean] relative to the result of controlling if its time to update or not.
.NOTES
    Uses the global variable $HealOpsConfig
.EXAMPLE
    $timeToUpdate = Confirm-TimeToUpdate -HealOpsConfig $HealOpsConfig
    Calls Confirm-TimeToUpdate in order to verify if an update cycle should run or not.
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
    if ($Config.checkForUpdatesNext.length -le 2) {
        <#
            - checkForUpdatesNext not correctly defined in the HealOps config json file or not defined at all. Assumption > check for updates now.
        #>
        Write-Verbose -Message "checkForUpdatesNext not correctly defined in the HealOps config json. Its value is > $($Config.checkForUpdatesNext)"
        $log4netLoggerDebug.debug("checkForUpdatesNext not correctly defined in the HealOps config json. So we should update. Its value is > $($Config.checkForUpdatesNext)")

        # Return
        $true
    } else {
        # checkedForUpdates properly defined. Control the date of the last update and hold it up against checkForUpdatesNext
        $currentDate = get-date
        $checkForUpdatesNext = $Config.checkForUpdatesNext -as [datetime]
        if ($currentDate -gt $checkForUpdatesNext) {
            $log4netLoggerDebug.debug("Its time for an update as the date of checkForUpdatesNext > $checkForUpdatesNext is below the current date > $currentDate. So we should update.")

            # Return
            $true
        } else {
            $log4netLoggerDebug.debug("$checkForUpdatesNext is above the current date > $currentDate. So we shouldn't update.")

            # Return
            $false
        }
    }
}