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
    <none>
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
        # HealOps packages
        if ($UpdateMode -eq "All" -or $UpdateMode -eq "HealOpsPackages") {
            [System.Collections.Generic.List[PSModuleInfo]]$ModulesToUpdate = Get-InstalledHealOpsPackage -All

            # The job user of HealOps ... its username
            New-Variable -Name HealOpsUsername -Value "HealOps" -Option Constant -Description "The username of the local administrator user, used by HealOps" `
            -Visibility Private -Scope Script

            # Password on the user
            if ($psVersionAbove4) {
                $Password = New-Password -PasswordType "SecureString"
                $clearTextJobPassword = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($Password))
            } else {
                $Password = New-Password -PasswordType "ClearText"
                $clearTextJobPassword = $Password
            }

            # Ensure that a local user for HealOps exists and works.
            try {
                $healOpsUserConfirmed = Resolve-HealOpsUserRequirement -Password $Password -UserName $HealOpsUsername
            } catch {
                $log4netLogger.error("Resolve-HealOpsUserRequirement failed with > $_")
                $healOpsUserConfirmed = $false
            }
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
                try {
                    $ModulesToUpdate.Add($HealOpsModule)
                } catch {
                    $log4netLogger.error("Failed to add the $HealOpsModuleName module to the ModulesToUpdate collection. Failed with > $_")
                }
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

                <#
                    - Handle HealOps package specifics
                #>
                if ($module.Name -match "\*HealOpsPackage") {
                    if ($healOpsUserConfirmed) {
                        # Get the HealOps package we just installed
                        [System.Collections.Generic.List[PSModuleInfo]]$installedHealOpsPackage = Get-InstalledHealOpsPackage -Package $module.Name

                        # Get the *.Tests.ps1 files in the HealOps package just installed.
                        if ($null -ne $installedHealOpsPackage -and $installedHealOpsPackage.Count -ge 1) {
                            [Array]$TestsFiles = Get-HealOpsPackageTestsFile -All -Package $installedHealOpsPackage
                        }

                        if ($TestsFiles.Count -ge 1) {
                            # Get the config file of the HealOps package
                            [Array]$HealOpsPackageConfig = Get-HealOpsPackageConfig -ModuleBase $installedHealOpsPackage.ModuleBase

                            if ($HealOpsPackageConfig.Count -ge 1) {
                                # Create a job per *.Tests.ps1 file in the current HealOps package
                                foreach ($testsFile in $TestsFiles) {
                                    # Determine the base FileName for the *.Tests.ps1 file
                                    $baseFileName = Get-TestsFileBaseName -HealOpsPackageConfig $HealOpsPackageConfig -TestsFile $testsFile

                                    # Get the jobInterval for the current job
                                    try {
                                        $currentErrorActionPreference = $ErrorActionPreference
                                        $ErrorActionPreference = "Stop"
                                        [int]$TestsFileJobInterval = $HealOpsPackageConfig.$baseFileName.jobInterval -as [int]
                                    } catch {
                                        $log4netLogger.error("Failed to determine the jobInterval value. Failed with > $_")
                                    } finally {
                                        $ErrorActionPreference = $currentErrorActionPreference
                                    }

                                    # Create a job to execute the retrieved *.Tests.ps1 file.
                                    if ($null -ne $TestsFileJobInterval) {
                                        try {
                                            New-HealOpsPackageJob -TestsBaseFileName $baseFileName -JobInterval $TestsFileJobInterval -JobType $Config.JobType -Package $installedHealOpsPackage -Password $clearTextJobPassword -UserName $HealOpsUsername
                                        } catch {
                                            $log4netLogger.error("Failed to create a job for the *.Tests.ps1 file named > $baseFileName. Failed with > $_")
                                        }
                                    }
                                }
                            } else {
                                $log4netLogger.error("No HealOps config file was returned. No HealOps jobs where created.")
                            }
                        } else {
                            $log4netLogger.error("There seems to be no *.Tests.ps1 files in the HealOps package named > $($module.name). No HealOps jobs where created.")
                        }
                    } else {
                        $log4netLogger.error("A HealOps package has been updated. However the HealOps user was not confirmed. This is bad! Jobs will likely not be able to execute now!`
                        The HealOps package that was updated is > $($module.Name)")
                        # TODO: Inform about this! Some handling of this situation is required!
                    }
                } # End of conditional control on $module being a HealOps package.
            } # End of foreach iteration over $ModulesToUpdate

            <#
                - Now configure the HealOps jobs that existed before executing this self-update cycle.
                    > We need to do this. If we don't, the jobs will not work as the password on the local HealOps user has been changed.
                    > Doesn't matter if the user existed already or not.
            #>
            if ($healOpsUserConfirmed) {
                $log4netLoggerDebug.Debug("Now configuring HealOps packages that was on the system before executing this self-update cycle.")

                # Get all packages not in $Packages
                [System.Collections.Generic.List[PSModuleInfo]]$HealOpsPackagesToUpdate = Get-InstalledHealOpsPackage -NotIn -PackageList $ModulesToUpdate

                if ($HealOpsPackagesToUpdate.Count -ge 1) {
                    foreach ($packageToUpdate in $HealOpsPackagesToUpdate) {
                        # Get the config file of the HealOps package
                        [Array]$HealOpsPackageConfig = Get-HealOpsPackageConfig -ModuleBase $packageToUpdate.ModuleBase

                        if ($HealOpsPackageConfig.Count -ge 1) {
                            # Get the *.Tests.ps1 files in the HealOps package
                            [Array]$TestsFiles = Get-HealOpsPackageTestsFile -Package $packageToUpdate

                            if ($TestsFiles.Count -ge 1) {
                                foreach ($testsFile in $TestsFiles) {
                                    # Get the BaseName of the *.Tests.ps1 file. Needed as this is the name of the task/job to get.
                                    $baseFileName = Get-TestsFileBaseName -HealOpsPackageConfig $HealOpsPackageConfig -TestsFile $testsFile

                                    if ($nulle -ne $baseFileName) {
                                        # Get the Scheduled task
                                        try {
                                            [CimInstance]$task = Get-xScheduledTask -TaskName $baseFileName
                                        } catch {
                                            $log4netLogger.error("Start-HealOpsUpdateCycle | Getting the scheduled task for $baseFileName failed with > $_")
                                        }

                                        if ($null -ne $task) {
                                            # Set the password on the job
                                            try {
                                                Set-xScheduledTask -InputObject $task -UserName $HealOpsUsername -Password $clearTextJobPassword
                                            } catch {
                                                $log4netLogger.error("$_")
                                            }
                                        } else {
                                            $log4netLoggerDebug.Debug("No job exists for the *.Tests.ps1 file named > $baseFileName. Creating one!")

                                            # Get the jobInterval to use
                                            try {
                                                $currentErrorActionPreference = $ErrorActionPreference
                                                $ErrorActionPreference = "Stop"
                                                [int]$TestsFileJobInterval = $HealOpsPackageConfig.$baseFileName.jobInterval -as [int]
                                            } catch {
                                                $log4netLogger.error("Start-HealOpsUpdateCycle | Failed to determine the jobInterval value. Failed with > $_")
                                            } finally {
                                                $ErrorActionPreference = $currentErrorActionPreference
                                            }

                                            # Create a task for the *.Tests.ps1 file as no one currently exists
                                            try {
                                                New-HealOpsPackageJob -TestsBaseFileName $baseFileName -JobInterval $TestsFileJobInterval -JobType $Config.JobType -Package $packageToUpdate -Password $clearTextJobPassword -UserName $HealOpsUsername
                                            } catch {
                                                $log4netLogger.error("Start-HealOpsUpdateCycle | Failed to create a job for the *.Tests.ps1 file named > $baseFileName. Failed with > $_")
                                            }
                                        }
                                    } else {
                                        Write-Output "Failed to get the BaseName of the *.Tests.ps1 file named > $testsFile. <-- you will have to set the password manually on the job."
                                        $log4netLogger.error("Failed to get the BaseName of the *.Tests.ps1 file named > $testsFile.")
                                    }
                                } # End of foreach *.Tests.ps1 file in the HealOps package to update.
                            } else {
                                Write-Output "No *.Tests.ps1 files was found in the package named > $($packageToUpdate.Name). Please control that this package is a proper HealOps package."
                                $log4netLogger.error("No *.Tests.ps1 files was found in the package named > $($packageToUpdate.Name).")
                            }
                        } else {
                            Write-Output "Failed to get the HealOps package config file. For the package named > $($packageToUpdate.Name). <-- you will have to set a password manually on the jobs for the *.Tests.ps1 files in this package."
                            $log4netLogger.error("Failed to get the HealOps package config file. For the package named > $($packageToUpdate.Name)")
                        } # End of conditional control on the HealOpsPackage config file.
                    } # End of foreach on HealOps packages to update.
                } else {
                    $log4netLoggerDebug.Debug("There seems to have been no HealOps packages installed on the system prior to executing a self-update cycle.")
                }
            } else {
                $log4netLoggerDebug.Debug("As the HealOps user was not changed, HealOps packages installed prior to executing a self-update cycle was not touched.")
            }
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
                $log4netLogger.error("Failed to register that an update cycle ran.")
            }
        }
    }
}