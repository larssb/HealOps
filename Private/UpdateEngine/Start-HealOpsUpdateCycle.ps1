function Start-HealOpsUpdateCycle() {
<#
.DESCRIPTION
    Updates a PowerShell module and its dependencies. This function expects that a Package Management is used to hold the module
    and its dependencies.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    Start-HealOpsUpdateCycle -ModuleName $ModuleName -Config $Config
    Start an update cycle so that the module specified as well as its dependencies is updated
.PARAMETER Config
    The config file holding package management repository info. Of the PSCustomObject type
.PARAMETER UpdateMode
    The execute mode that the self-update should use.
        > All = Everything will be updated. HealOps itself, its required modules and the HealOps packages on the system.
        > HealOpsPackages = Only HealOps packages will be updated.
        > HealOps = Only HealOps itself and its requird modules will be updated.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The HealOps (main module) config file. That holds package management repository info. A PSCustomObject type")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The execute mode that the self-update should use.")]
        [ValidateSet("All","HealOpsPackages","HealOps")]
        [String]$UpdateMode
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Prep. and sanity checks
        #>
        # Check for the temp download folder
        $tempDirPath = "$PSScriptRoot/../../Artefacts/Temp"
        if (-not (Test-Path -Path $tempDirPath)) {
            try {
                New-Item -Path "$PSScriptRoot/../../Artefacts" -Name "Temp" -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                $log4netLogger.error("Failed to create the temp download folder. The failure was > $_")
            }
        } else {
            # Clean-up temp before starting. To avoid issues with copying, moving and generally handling files
            try {
                Get-ChildItem -Path $tempDirPath -Force -Recurse -ErrorAction Stop | Remove-Item -Force -Recurse -ErrorAction Stop
            } catch {
                $log4netLogger.error("Cleaning up the download temp dir > $tempDirPath faild with > $_")
            }
        }

        <#
            - Variables
        #>
        # List to contain modules to be updated
        $ModulesToUpdate = New-Object System.Collections.Generic.List[PSModuleInfo]

        # The name of the main module > HealOps
        [String]$HealOpsModuleName = "HealOps"
    }
    Process {
        if ($UpdateMode -eq "All" -or $UpdateMode -eq "HealOpsPackages") {

            ##### ! IS THIS CORRECT????
            $ModulesToUpdate = Get-InstalledHealOpsPackage -All
        }

        if ($UpdateMode -eq "All" -or $UpdateMode -eq "HealOps") {
            try {
                # Get the main module. The newest version of it, if several is installed
                [PSModuleInfo]$HealOpsModule = Get-LatestModuleVersionLocally -ModuleName $HealOpsModuleName
            } catch {
                $log4netLogger.error("Failed to get the main module > $HealOpsModuleName on the system. It failed with > $_")
            }

            if ($null -ne $HealOpsModule) {
                # Add the module to the list
                $ModulesToUpdate.Add($HealOpsModule)
            } else {
                $log4netLoggerDebug.debug("The main module > $HealOpsModuleName, could not be found on the system.")
            }
        }

        # Iterate over each module to be updated (if any)
        if ($ModulesToUpdate.Count -ge 1) {
            foreach ($module in $ModulesToUpdate) {
                <#
                    - The dependencies of the module - if any
                #>
                if ($module.RequiredModules.Count -ge 1) {
                    foreach ($requiredModule in $module.RequiredModules) {
                        # Register the required version of the module that the main module is dependent on
                        $moduleVersionBeforeUpdate = $requiredModule.version

                        # Check the Package Management backend for an available update to the current dependency module
                        $availableUpdateResult = Get-AvailableUpdate -ModuleName $requiredModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate -Config $Config

                        if ($null -ne $availableUpdateResult.Version) {
                            try {
                                # Get the module. The newest version of it, if several is installed
                                $requiredModule = Get-LatestModuleVersionLocally -ModuleName $requiredModule.Name
                            } catch {
                                $log4netLogger.error("Failed to get the module > $($requiredModule.Name) on the system. It failed with > $_")
                            }

                            # Determine the path to extract a downloaded module to
                            $extractModulePath = Get-ModuleExtractionPath -ModuleName $requiredModule.Name -Version $availableUpdateResult.Version

                            # Update the module
                            try {
                                $installResult = Install-AvailableUpdate -ModuleName $requiredModule.Name -ModuleExtractionPath $extractModulePath -PackageManagementURI $config.PackageManagementURI -FeedName $Config.FeedName -Version $availableUpdateResult.Version
                            } catch {
                                $log4netLogger.error("Install-AvailableUpdate failed with > $_")
                            }

                            if ($installResult -eq $true) {
                                # Control if the module was actually updated after a non-failing Install-AvailableUpdate execution and log it
                                Test-ModuleUpdated -ModuleName $requiredModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate

                                # Remove the contents of the download temp dir.
                                try {
                                    Get-ChildItem -Path $tempDirPath -Force -Recurse -ErrorAction Stop | Remove-Item -Force -Recurse -ErrorAction Stop
                                } catch {
                                    $log4netLogger.error("Cleaning up the download temp dir > $tempDirPath faild with > $_")
                                }
                            }
                        } else {
                            $log4netLoggerDebug.debug("There was no newer version of the module: $($requiredModule.Name) - on the Package Management backend.")
                        }
                    }
                }

                <#
                    - The main module
                #>
                # Register the current version of the module
                $moduleVersionBeforeUpdate = $module.Version

                # Check the Package Management backend for an available update to the current dependency module
                $availableUpdateResult = Get-AvailableUpdate -ModuleName $module.Name -CurrentModuleVersion $moduleVersionBeforeUpdate -Config $Config

                if ($null -ne $availableUpdateResult.Version) {
                    # Determine the path to extract a downloaded module to
                    $extractMainModulePath = Get-ModuleExtractionPath -ModuleName $module.Name -Version $availableUpdateResult.Version

                    # Update the module
                    try {
                        $installResultMainModule = Install-AvailableUpdate -ModuleName $module.Name -ModuleExtractionPath $extractMainModulePath -PackageManagementURI $config.PackageManagementURI -FeedName $Config.FeedName -Version $availableUpdateResult.Version
                    } catch {
                        $log4netLogger.error("Install-AvailableUpdate failed with > $_")
                    }

                    if ($installResultMainModule -eq $true) {
                        # Control if the module was actually updated after a non-failing Install-AvailableUpdate execution and log it
                        Test-ModuleUpdated -ModuleName $module.Name -CurrentModuleVersion $moduleVersionBeforeUpdate

                        # Remove the contents of the download temp dir.
                        try {
                            Get-ChildItem -Path $tempDirPath -Force -Recurse -ErrorAction Stop | Remove-Item -Force -Recurse -ErrorAction Stop
                        } catch {
                            $log4netLogger.error("Cleaning up the download temp dir > $tempDirPath faild with > $_")
                        }
                    }
                } else {
                    $log4netLoggerDebug.debug("There was no newer version of the module: $($module.Name) - on the Package Management backend.")
                }
            } # End of foreach iteration over $ModulesToUpdate
        } else {
            $log4netLoggerDebug.debug("No modules where found. So no modules was updated. The update mode was set to > $UpdateMode.")
        } # End of conditional amount control on $ModulesToUpdate
    }
    End {
        <#
            - Register that an update cycle ran
        #>
        try {
            # Refresh info on the latest version of the HealOps module after having ran an update cycle
            $MainModule = Get-LatestModuleVersionLocally -ModuleName $HealOpsModuleName
        } catch {
            $log4netLogger.error("Failed to get the latest module version of $HealOpsModuleName. It failed with > $_")
        }

        if($null -ne $MainModule.ModuleBase) {
            # Register that the main module was updated.
            $registerResult = Register-UpdateCycle -Config $Config -ModuleBase $MainModule.ModuleBase

            if ($registerResult -eq $false) {
                $log4netLogger.error("Failed to register that an update cycle ran. See any possible [ERROR] in the log.")
            }
        }
    }
}