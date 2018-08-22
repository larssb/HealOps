function Sync-HealOpsConfig() {
<#
.DESCRIPTION
    Syncs changes from the current HealOps config and an updated HealOps config to the HealOps config file to be used going forward.
.INPUTS
    [System.Array] representing the changes between the current and an updated version of the HealOps config file.
.OUTPUTS
    [PSCustomObject] representing the data to write to the HealOps config file to be used going forward.
.NOTES
    - This function will likely have to be updated regularly. Or in other words, as often as you update/change the HealOps config file.
.EXAMPLE
    [PSCustombObject]$syncedConfig = Sync-HealOpsConfig -configChanges $configChanges -currentConfig $currentConfig
        > Syncs the changes that was found the current HealOps config file and the one from an updated version of HealOps.
        > The changes are returned as a PSCustomObject that can be written to the HealOps config file to be used going forward.
.PARAMETER ConfigChanges
    The changes between the current HealOps config and an HealOps config from an updated version of HealOps.
.PARAMETER CurrentConfig
    The current HealOps config file. To be compared with the HealOps config file coming in from an updated version of HealOps.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([PSCustomObject])]
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({$_.Count -ge 1})]
        [System.Array]$ConfigChanges,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$CurrentConfig
    )

    #############
    # Execution #
    #############
    Begin {
        if ($null -eq $CurrentConfig.psobject) {
            $log4netLogger.error("Sync-HealOpsConfig > The psobject property is not on the currentConfig object. Pass a valid object passed!")
            throw "Sync-HealOpsConfig > The psobject property is not on the currentConfig object. Pass a valid object passed!"
        }

        <#
            - Variables
        #>
        New-Variable -Name addMemberFailureMessage -Value "Sync-HealOpsConfig | Failed to add a new member to the currentConfig object. Failed with >" -Option ReadOnly -Description "addMemberFailureMessage" -Visibility Private -Scope Script
        New-Variable -Name checkForUpdatesInterval -Value "checkForUpdatesInterval_Hours" -Option ReadOnly -Description "The checkForUpdatesInterval_Hours property" -Visibility Private -Scope Script
        New-Variable -Name checkForUpdatesIntervalDefaultValue -Value "24" -Option ReadOnly -Description "The default update interval value." -Visibility Private -Scope Script
        New-Variable -Name JobType -Value "JobType" -Option ReadOnly -Description "The JobType property" -Visibility Private -Scope Script
        New-Variable -Name UpdateMode -Value "UpdateMode" -Option ReadOnly -Description "The UpdateMode property" -Visibility Private -Scope Script

        # Make sure that calls which lack -ErrorAction prefs. and are per default not terminating on failures do fail in a terminating way.
        $currentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
    }
    Process {
        $log4netLoggerDebug.Debug("ConfigChanges holds > $ConfigChanges")

        foreach ($item in $configChanges) {
            switch ($item) {
                { $_ -match "checkForUpdatesInterval_*" } {
                    <#
                        - The checkForUpdatesInterval_ property was changed from _InDays to _InHours. Ensure that the config file to be used going forward reflects this.
                    #>
                    # Get the checkForUpdatesInterval property. Matching on the part that wasn't changed.
                    [String]$intervalValue = $CurrentConfig.psobject.Properties.name -match "checkForUpdatesInterval_(?<content>.*)"

                    # Compare the value with the updated property value
                    [bool]$intervalValueCompareResult = "$checkForUpdatesInterval" -match $intervalValue

                    if (-not $intervalValueCompareResult) {
                        #### The current property does not match the updated value of the property. Reflect this.
                        # Remove the property from the object
                        try {
                            $CurrentConfig.psobject.Properties.Remove($intervalValue)
                        } catch {
                            $message = "Sync-HealOpsConfig | Failed to remove the property named > $intervalValue. Failed with > $_"
                            $log4netLogger.error("$message")
                            throw "$message"
                        }

                        # Add the updated property
                        try {
                            Add-Member -InputObject $currentConfig -MemberType NoteProperty -Name "$checkForUpdatesInterval" -Value $checkForUpdatesIntervalDefaultValue -TypeName "System.String" -ErrorAction Stop
                        } catch {
                            $message = "$addMemberFailureMessage $_"
                            $log4netLogger.error("$message")
                            throw "$message"
                        }
                    }
                }
                "JobType" {
                    <#
                        - The JobType property
                            > This one is an entirely new property so we need to ensure that the property is there > not update a change to an existing property
                    #>
                    # Control if it is in the properties list.
                    [bool]$jobTypeLookupResult = $CurrentConfig.psobject.Properties.name.Contains("$JobType")

                    if (-not $jobTypeLookupResult) {
                        # Figure out the value to give JobType
                        try {
                            $os = get-environmentOS
                            switch ($os) {
                                "Windows" { $JobTypeValue = "WinScTask" }
                                "Linux" { $JobTypeValue = "LinCronJob" }
                                Default {
                                    throw "Sync-HealOpsConfig | The value returned by get-environmentOS is not supported."
                                }
                            }
                        } catch {
                            throw $_
                        }

                        # The property is not already there. Add it.
                        try {
                            Add-Member -InputObject $CurrentConfig -MemberType NoteProperty -Name "$JobType" -Value $JobTypeValue -TypeName "System.String" -ErrorAction Stop
                        } catch {
                            $message = "$addMemberFailureMessage $_"
                            $log4netLogger.error("$message")
                            throw "$message"
                        }
                    }
                }
                "UpdateMode" {
                    <#
                        - The UpdateMode property
                            > This one is an entirely new property so we need to ensure that the property is there > not update a change to an existing property
                    #>
                    # Control if it is in the properties list.
                    [bool]$updateModeLookupResult = $currentConfig.psobject.Properties.name.Contains("$UpdateMode")

                    if (-not $updateModeLookupResult) {
                        # The property is not already there. Add it.
                        try {
                            # Fall-back value to UpdateMode should always be HealOpsPackages (that is what is updated when the self-update feature runs)
                            Add-Member -InputObject $currentConfig -MemberType NoteProperty -Name "$UpdateMode" -Value "HealOpsPackages" -TypeName "System.String" -ErrorAction Stop
                        } catch {
                            $message = "$addMemberFailureMessage $_"
                            $log4netLogger.error("$message")
                            throw "$message"
                        }
                    }
                }
                Default {
                    $log4netLoggerDebug.debug("Sync-HealOpsConfig | The item > $item, in the configChanges Array did not match any of the options.")
                    Write-Verbose -Message "Sync-HealOpsConfig | The item > $item, in the configChanges Array did not match any of the options."
                }
            }
        } # End of foreach item in the configChanges Array
    }
    End {
        # Clean-up
        $ErrorActionPreference = $currentErrorActionPreference

        # Return
        $currentConfig
    }
}