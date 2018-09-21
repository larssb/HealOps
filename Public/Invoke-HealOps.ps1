function Invoke-HealOps() {
<#
.DESCRIPTION
    Invoke-HealOps is the function you call to initiate the *.Tests.ps1 and *.Repairs.ps1 files in "X" HealOps package.
        - The Pester tests in the *.Test.ps1 file will executed
        - If the component being tested is in a filed state it will be tried remediated via a *.Tests.ps1 corresponding *.Repairs.ps1 file.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    - Uses the global variables:
        -- psVersionAbove4 > Used to execte either 'A' or 'B' set of code, in relation to the current PowerShell runtime version.
        -- runMode > Used to test on, in order to know if we should output to an interactive session.
.EXAMPLE
    Invoke-HealOps -TestsFileName Citrix.Services.ps1 -HealOpsPackage Citrix.HealOpsPackage
    Executes HealOps on a specific *.Tests.ps1 file. Sending in the HealOps package config file wherein HealOps will read configuration and tags.
.PARAMETER ForceUpdate
    Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.
.PARAMETER HealOpsPackageName
    The name of the HealOps package that the TestsFileName belong to.
.PARAMETER ReportMode
    Used to indicate that HealOps should run in "ReportMode" mode. Having the effect that a failed state will only be reported and not tried repaired.
.PARAMETER StatsFileName
    The name of the *.Stats.ps1 file to execute. The Statsfile is part of the HealOps package specified via the HealOpsPackageName parameter.
.PARAMETER TestsFileName
    The name of the *.Tests.ps1 file to execute. The testsfile is part of the HealOps package specified via the HealOpsPackageName parameter.
.PARAMETER UpdateMode
    The execute mode that the self-update should use.
        > All = Everything will be updated. HealOps itself, its required modules and the HealOps packages on the system.
        > HealOpsPackages = Only HealOps packages will be updated.
        > HealOps = Only HealOps itself and its requird modules will be updated.
    NOTE: HealOpsPackages is the default value. Used when the config is corrupt.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Void])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars","")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
    Param(
        [Parameter(ParameterSetName="Tests")]
        [Parameter(ParameterSetName="Stats")]
        [Switch]$ForceUpdate,
        [Parameter(Mandatory, ParameterSetName="Tests")]
        [Parameter(Mandatory, ParameterSetName="Stats")]
        [ValidateNotNullOrEmpty()]
        [String]$HealOpsPackageName,
        [Parameter(ParameterSetName="Tests")]
        [Switch]$ReportMode,
        [Parameter(Mandatory, ParameterSetName="Stats")]
        [ValidateNotNullOrEmpty()]
        [String]$StatsFileName,
        [Parameter(Mandatory, ParameterSetName="Tests")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsFileName,
        [Parameter(ParameterSetName="Stats")]
        [Parameter(ParameterSetName="Tests")]
        [ValidateSet("All","HealOpsPackages","HealOps")]
        [String]$UpdateMode = "HealOpsPackages"
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Configure logging
        #>
        # Define log4net variables
        $log4NetConfigFile = "$PSScriptRoot/../Artefacts/HealOps.Log4Net.xml"
        $LogFilesPath = "$PSScriptRoot/../Artefacts"

        # Initiate the log4net logger
        if($PSCmdlet.ParameterSetName -eq "Tests") {
            $logfileName_GeneratedPart = (Split-Path -Path $TestsFileName -Leaf) -replace ".ps1",""
        } elseif ($PSCmdlet.ParameterSetName -eq "Stats") {
            $logfileName_GeneratedPart = (Split-Path -Path $StatsFileName -Leaf) -replace ".ps1",""
        } else {
            $logfileName_GeneratedPart = "ForceUpdate"
        }
        $global:log4netLogger = initialize-log4net -log4NetConfigFile $log4NetConfigFile -LogFilesPath $LogFilesPath -logfileName "HealOps.$logfileName_GeneratedPart" -loggerName "HealOps_Error"
        $global:log4netLoggerDebug = initialize-log4net -log4NetConfigFile $log4NetConfigFile -LogFilesPath $LogFilesPath -logfileName "HealOps.$logfileName_GeneratedPart" -loggerName "HealOps_Debug"

        # Make the log more viewable.
        $log4netLoggerDebug.debug("--------------------------------------------------")
        $log4netLoggerDebug.debug("------------- HealOps logging started ------------")
        $log4netLoggerDebug.debug("------------- $((get-date).ToString()) -----------")
        $log4netLoggerDebug.debug("--------------------------------------------------")

        # Note the version of PowerShell we are working with.
        $log4netLoggerDebug.debug("The PowerShell version is: $($PSVersionTable.PSVersion.ToString()). The value of psVersionAbove4 is $psVersionAbove4")

        <#
            - ReadOnly variables.
        #>
        if ($PSCmdlet.ParameterSetName -eq "Tests") {
            # Constant for reporting on Repair status of "X" component og an IT service.
            New-Variable -Name RepairSuccessValue -Value 1 -Option ReadOnly -Description "Represent truthy in relation to the result of repairing 'X' component of an IT service" `
            -Visibility Private -Scope Script -Force
            New-Variable -Name RepairFailedValue -Value 0 -Option ReadOnly -Description "Represent falsy in relation to the result of repairing 'X' component of an IT service" `
            -Visibility Private -Scope Script -Force
        }

        # The name of the HealOps module.
        if(-not (Get-variable -Name mainModuleName -ErrorAction SilentlyContinue) -eq $true) {
            try {
                New-Variable -Name mainModuleName -Value "HealOps" -Option ReadOnly -Description "The name of the HealOps module" -Visibility Private -Scope Script -Force -ErrorAction Stop
            } catch {
                $log4netLogger.error("Invoke-HealOps | Failed to declared the 'MainModuleName' variable. The error is > $_")
            }
        }

        <#
            - Sanity tests
        #>
        $HealOpsConfigPath = "$PSScriptRoot/../Artefacts/HealOpsConfig.json"
        if(-not (Test-Path -Path $HealOpsConfigPath)) {
            $message = "The file > $HealOpsConfigPath cannot be found. Please provide a HealOpsConfig.json file."
            Write-Verbose -Message $message
            $log4netLogger.error("$message")

            # Exit
            throw $message
        } else {
            try {
                # Obtain a lock on the HealOps config file
                [System.IO.FileStream]$HealOpsConfigFile = Lock-HealOpsConfig -HealOpsConfigPath $HealOpsConfigPath

                # Read the config
                $HealOpsConfigReader = New-Object System.IO.StreamReader($HealOpsConfigFile)
                $HealOpsConfigText = $HealOpsConfigReader.ReadToEnd()

                # To array type object for easy of reading
                if ($psVersionAbove4) {
                    [PSCustomObject]$HealOpsConfig = $HealOpsConfigText | ConvertFrom-Json
                } else {
                    [PSCustomObject]$HealOpsConfig = $HealOpsConfigText | Out-String | ConvertFrom-Json
                }

                # Mark semaphore signaling that we are a' okay! to run a self-update cycle.
                $canRunUpdate = $true
                $log4netLoggerDebug.Debug("The HealOps config file was successfully locked.")
            } catch {
                $log4netLoggerDebug.Debug("The HealOps config file could not be locked. It is already being used. An update cyclus might therefore be occurring.")

                # Mark semaphore to signal that we should not run an update as another process is potentially doing that already.
                $canRunUpdate = $false
            }

            if (-not $canRunUpdate) {
                # Failed to lock the HealOps config as another process is using it. Still need to read the config for this session to run is *.Tests.ps1 and *.Repairs.ps1 files.
                if($psVersionAbove4) {
                    [PSCustomObject]$HealOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
                } else {
                    [PSCustomObject]$HealOpsConfig = Get-Content -Path $HealOpsConfigPath | out-string | ConvertFrom-Json
                }

            }

            if ($null -eq $HealOpsConfig) {
                $message = "The HealOpsConfig contains no data. Please generate a proper HealOps config file. See the documentation."
                Write-Verbose -Message $message
                $log4netLogger.error("$message")

                # Exit
                throw $message
            } elseif(-not ($healOpsConfig.Metrics.System.Length -gt 1)) {
                $message = "The HealOps config file is invalid. Please generate a proper HealOps config file. See the documentation."
                Write-Verbose -Message $message
                $log4netLogger.error("$message")

                # Exit
                throw $message
            }
        }

        <#
            - Determine HealOps package related values
        #>
        # Get the latest locally available version of the HealOps package
        try {
            $LatestHealOpsPackage = Get-LatestModuleVersionLocally -ModuleName $HealOpsPackageName
        } catch {
            # Log it
            $log4netLogger.error("$_")

            # Exit
            throw $_
        }

        if ($PSCmdlet.ParameterSetName -eq "Tests") {
            # Get the testsfile named as in $TestsFileName
            try {
                $TestsFile = Get-PS1File -FileName $TestsFileName -ModuleName $HealOpsPackageName
            } catch {
                # Exit
                throw $_
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Stats") {
            # Get the Stats file named as in $StatsFileName
            try {
                $StatsFile = Get-PS1File -FileName $StatsFileName -ModuleName $HealOpsPackageName
            } catch {
                # Exit
                throw $_
            }
        }

        # Control the config file in the HealOps package
        try {
            $HealOpsPackageConfigFile = Get-ChildItem -Path $LatestHealOpsPackage.ModuleBase -Include *.json -Recurse -ErrorAction Stop
        } catch {
            $message = "Getting the HealOps package config json file failed with > $_"
            # Log it
            $log4netLogger.error("$message")

            # Exit
            throw $message
        }

        if($HealOpsPackageConfigFile.count -eq 1) {
            # Check file integrity & get config data
            if($psVersionAbove4) {
                [PSCustomObject]$global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigFile.FullName -Encoding UTF8 | ConvertFrom-Json
            } else {
                [PSCustomObject]$global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigFile.FullName | out-string | ConvertFrom-Json
            }

            if ($null -eq $HealOpsPackageConfig) {
                $message = "The HealOps package config contains no data. Please provide a proper HealOps package config file."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit
                throw $message
            } elseif($null -eq $HealOpsPackageConfig[0]) {
                $message = "The HealOps package config file is not valid. Please provide a proper one."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit
                throw $message
            }
        } else {
            $message = "More than 1 config file seems to exist for the HealOps package > $HealOpsPackageName. A HealOps package should only contain 1 config json file."
            Write-Verbose -Message $message

            # Log it
            $log4netLogger.error("$message")

            # Exit
            throw $message
        }

        <#
            - General module runtime config
        #>
        # Handle verbosity
        if ($PSBoundParameters.ContainsKey("Verbose")) {
            $CommonParms = @{ "Verbose" = $true }
        } else {
            $CommonParms = @{ "Verbose" = $false }
        }

        <#
            - Check for updates. For the modules that HealOps has a dependency on and for HealOps itself
        #>
        if ($canRunUpdate) {
            if($healOpsConfig.checkForUpdates -eq "True") {
                if (-not $ForceUpdate) {
                    $timeForUpdate = Confirm-TimeToUpdate -Config $HealOpsConfig
                }

                if ($timeForUpdate -eq $true -or $ForceUpdate -eq $true) {
                    # Debug info - register that forceupdate was used.
                    if ($ForceUpdate -eq $true) {
                        $log4netLoggerDebug.debug("The force update parameter was used.")
                    }

                    try {
                        # Control if the -UpdateMode param. was set. If so use its value
                        if ($PSBoundParameters.ContainsKey('UpdateMode')) {
                            $log4netLoggerDebug.debug("The UpdateMode param. was used to overwrite the use of the UpdateMode property in the HealOps config file. UpdateMode was temporarily set to > $UpdateMode)")
                            $actualUpdateMode = $UpdateMode
                        } else {
                            $log4netLoggerDebug.debug("The value of > UpdateMode in the HealOps config json file > $($healOpsConfig.UpdateMode)")
                            $actualUpdateMode = $healOpsConfig.UpdateMode
                        }

                        # Call Start-HealOpsUpdateCycle to execute the self-update feature
                        Start-HealOpsUpdateCycle -UpdateMode $actualUpdateMode -Config $healOpsConfig
                    } catch {
                        $log4netLogger.error("Start-HealOpsUpdateCycle failed with: $_")
                    }
                } else {
                    # The update cycle did not run.
                    $log4netLoggerDebug.debug("The update cycle did not run. It is not the time for updating.")
                    Write-Verbose -Message "The update cycle did not run. It is not the time for updating."
                }
            } else {
                $log4netLoggerDebug.debug("The self-update feature is disabled.")
            }
        } else {
            $log4netLoggerDebug.Debug("canRunUpdate has a value of $canRunUpdate. Therefore the self-update feature, if enabled, will be denied executing. In order to avoid conflicting
            with other instances of HealOps already in a self-update cycle.")
            if($runMode) {
                Write-Output "canRunUpdate has a value of $canRunUpdate. Therefore the self-update feature, if enabled, will be denied executing. In order to avoid conflicting
                with other instances of HealOps already in a self-update cycle."
            }
        } # End of confitional control on canRunUpdate. This semaphore needs to be true. If false another process is already in the proces of running a self-update cycle.
    }
    Process {
        ##############
        # TESTS MODE #
        ##############
        if ($PSCmdlet.ParameterSetName -eq "Tests") {
            # Test execution
            Write-Verbose -Message "Invoke-HealOps | Executing the test"
            try {
                [Hashtable]$TestResult = Test-EntityState -TestFilePath $TestsFile.FullName -ErrorAction Stop
            } catch {
                $log4netLogger.error("Invoke-HealOps | Test-EntityState failed with: $_")
            }

            if (($TestResult.state -eq $false) -and (-not ($PSBoundParameters.ContainsKey('ReportMode')))) {
                ###################
                # The test failed #
                ###################
                Write-Verbose -Message "Invoke-HealOps | Trying to repair the 'Failed' test/s."
                $log4netLoggerDebug.debug("Invoke-HealOps | Trying to repair the 'Failed' test/s.")
                try {
                    # Invoke repairs matching the failed test
                    $ResultOfRepair = Repair-EntityState -TestFilePath $TestsFile.FullName -TestData $TestResult.TestData -ErrorAction Stop @CommonParms
                } catch {
                    $log4netLogger.error("Invoke-HealOps | Repair-EntityState failed with: $_")
                }

                if ($ResultOfRepair -eq $false) {
                    Write-Verbose -Message "Reporting metrics on a failed repair of an entity state."
                    if ($null -ne $TestResult) {
                        foreach ($item in $TestResult.TestData) {
                            # Parameter splatting for the Submit-EntityStateReport function.
                            $SubmitEntityStateReport_Parms = @{
                                Config = $HealOpsConfig
                                Data = $($item.MetricData)
                                ErrorAction = "Stop"
                                Metric = $($item.Metric)
                                MetricsSystem = $($HealOpsConfig.Metrics.System)
                                Verbose = $CommonParms['Verbose']
                            }

                            # Submit the metric to the Metrics backend.
                            try {
                                Submit-EntityStateReport @SubmitEntityStateReport_Parms
                            } catch {
                                $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                                Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                            }

                            try {
                                # Report that the repair succeeded on the component
                                Submit-EntityStateReport -Config $HealOpsConfig -MetricsSystem $($HealOpsConfig.Metrics.System) -Metric $($item.Metric) -RepairMetricValue $RepairFailedValue @CommonParms -ErrorAction Stop
                            } catch {
                                $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                                Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                            }
                        }
                    } else {
                        $log4netLogger.error("Invoke-HealOps | No TestResult retrieved.")
                        Write-Verbose "Invoke-HealOps | No TestResult retrieved."
                    } # End of conditional on $TestResult
                } else {
                    Write-Verbose -Message "Testing again, on a successfully repaired entity state. In case something went rotten in the repair, we fetch the newest metric value."
                    try {
                        # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                        $TestResult = Test-EntityState -TestFilePath $TestsFile.FullName -ErrorAction Stop
                    } catch {
                        # Log it
                        $log4netLogger.error("Invoke-HealOps | Test-EntityState failed with: $_")
                    }

                    Write-Verbose -Message "Reporting metrics on a successfull repair of an entity state."
                    if ($null -ne $TestResult) {
                        foreach ($item in $TestResult.TestData) {
                            # Parameter splatting for the Submit-EntityStateReport function.
                            $SubmitEntityStateReport_Parms = @{
                                Config = $HealOpsConfig
                                Data = $($item.MetricData)
                                ErrorAction = "Stop"
                                Metric = $($item.Metric)
                                MetricsSystem = $($HealOpsConfig.Metrics.System)
                                Verbose = $CommonParms['Verbose']
                            }

                            # Submit the metric to the Metrics backend.
                            try {
                                Submit-EntityStateReport @SubmitEntityStateReport_Parms
                            } catch {
                                $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                                Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                            }

                            try {
                                # Report that the repair succeeded on the component
                                Submit-EntityStateReport -Config $HealOpsConfig -MetricsSystem $($HealOpsConfig.Metrics.System) -Metric $($item.Metric) -RepairMetricValue $RepairSuccessValue @CommonParms -ErrorAction Stop
                            } catch {
                                $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                                Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                            }
                        }
                    } else {
                        $log4netLogger.error("Invoke-HealOps | No TestResult retrieved.")
                        Write-Verbose "Invoke-HealOps | No TestResult retrieved."
                    } # End of conditional on $TestResult
                }
            } else {
                ######################
                # The test succeeded #
                ######################
                Write-Verbose -Message "Reporting metrics on a successfully tested entity state."
                if ($null -ne $TestResult) {
                    foreach ($item in $TestResult.TestData) {
                        # Parameter splatting for the Submit-EntityStateReport function.
                        $SubmitEntityStateReport_Parms = @{
                            Config = $HealOpsConfig
                            Data = $($item.MetricData)
                            ErrorAction = "Stop"
                            Metric = $($item.Metric)
                            MetricsSystem = $($HealOpsConfig.Metrics.System)
                            Verbose = $CommonParms['Verbose']
                        }

                        # Submit the metric to the Metrics backend.
                        try {
                            Submit-EntityStateReport @SubmitEntityStateReport_Parms
                        } catch {
                            $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                            Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                        }
                    }
                } else {
                    $log4netLogger.error("Invoke-HealOps | No TestResult retrieved.")
                    Write-Verbose "Invoke-HealOps | No TestResult retrieved."
                } # End of conditional on $TestResult
            } # End of conditional control on failed state and not in ReportMode.
        } # End of conditional control on ParameterSetName -eq "Tests".

        ##############
        # STATS MODE #
        ##############
        if ($PSCmdlet.ParameterSetName -eq "Stats") {
            # Stats gathering
            Write-Verbose -Message "Gathering stats"
            try {
                $Stats = Read-EntityStats -StatsFilePath $StatsFile.FullName @CommonParms -ErrorAction Stop
            } catch {
                $log4netLogger.error("Invoke-HealOps | Read-EntityStats failed with: $_")
            }

            if (($null -ne $Stats) -and ($Stats.Count -gt 0)) {
                foreach ($item in $Stats) {
                    if ($null -ne $item.MetricData) {
                        $MetricValueType = $item.MetricData.Value.GetType().Name
                        if ($MetricValueType -eq "Int32") {
                            # Parameter splatting for the Submit-EntityStateReport function.
                            $SubmitEntityStateReport_Parms = @{
                                Config = $HealOpsConfig
                                Data = $($item.MetricData)
                                ErrorAction = "Stop"
                                Metric = $($item.Metric)
                                MetricsSystem = $($HealOpsConfig.Metrics.System)
                                Verbose = $CommonParms['Verbose']
                            }

                            if ($null -ne $Item.StatsOwner) {
                                $SubmitEntityStateReport_Parms.Add("StatsOwner", $Item.StatsOwner)
                            }

                            # Submit the stats to the reporting backend.
                            try {
                                Submit-EntityStateReport @SubmitEntityStateReport_Parms
                            } catch {
                                $log4netLogger.error("Invoke-HealOps | Submit-EntityStateReport failed with: $_")
                                Write-Verbose "Invoke-HealOps | Submit-EntityStateReport failed with: $_"
                            }
                        } else {
                            $log4netLogger.error("Invoke-HealOps | The value property in MetricData is of the wrong type. Its value is $MetricValueType. The metric will not be reported.")
                            Write-Verbose "Invoke-HealOps | The value property in MetricData is of the wrong type. Its value is $MetricValueType. The metric will not be reported."
                        } # End of conditional control on the type of Int32.
                    } else {
                        $log4netLogger.error("Invoke-HealOps | The MetricData property isn't defined in MetricData. The metric will not be reported.")
                        Write-Verbose "Invoke-HealOps | The MetricData property in MetricData is not correctly defined. The metric will not be reported."
                    } # End of conditional control on MetricData not $null
                }
            } else {
                $log4netLogger.error("Invoke-HealOps | No stats retrieved.")
                Write-Verbose "Invoke-HealOps | No stats retrieved."
            }
        } # End of conditional control on ParameterSetName -eq "Stats".
    } # End of Process {} declaration
    End {
        # Clean-up
        if ($canRunUpdate) {
            # Close the resources used to read and lock the HealOps config file
            try {
                $HealOpsConfigFile.Dispose()
                $HealOpsConfigFile.Close()
                $HealOpsConfigReader.Dispose()
                $HealOpsConfigReader.Close()
                $log4netLoggerDebug.Debug("Invoke-HealOps | canRunUpdate was $canRunUpdate. Successfully closed the HealOps config lock & read resources.")
            } catch {
                $log4netLogger.error("Invoke-HealOps | canRunUpdate was $canRunUpdate. Couldn't clean-up the HealOps config lock & read resources. Failed with > $_")
            }

            if ($timeForUpdate -eq $true -or $ForceUpdate -eq $true) {
                <#
                    - Register that an update cycle ran
                #>
                try {
                    # Refresh info on the latest version of the HealOps module after having ran an update cycle
                    [PSModuleInfo]$MainModule = Get-LatestModuleVersionLocally -ModuleName $mainModuleName
                } catch {
                    $log4netLogger.error("Invoke-HealOps | Failed to get the latest module version of HealOps. It failed with > $_")
                }

                <#
                    - Remove and import the latest version. If not we cannot properly update the HealOps config file with potential changes as the updated functions to compare and so forth has
                    not been read into memory.
                        > This should therefore reload the HealOps module so that the Register-UpdateCycle and the functions it uses are of their latest version in mem.
                #>
                try {
                    Remove-Module -Name $mainModuleName -Force -ErrorAction Stop
                } catch {
                    $log4netLogger.error("Failed to remove the $mainModuleName module. Failed with > $_")
                }

                try {
                    Import-Module -Name $mainModuleName -Force -ErrorAction Stop
                } catch {
                    $log4netLogger.error("Failed to import the $mainModuleName module. Failed with > $_")
                }

                if($null -ne $MainModule.ModuleBase) {
                    # Register that the main module was updated.
                    . "$($MainModule.ModuleBase)/Private/UpdateEngine/Register-UpdateCycle.ps1"
                    $registerResult = Register-UpdateCycle -Config $HealOpsConfig -ModuleBase $MainModule.ModuleBase

                    if ($registerResult -eq $false) {
                        $log4netLogger.error("Failed to register that an update cycle ran.")
                    } else {
                        $log4netLoggerDebug.Debug("UpdateCycle registered")
                    }
                } else {
                    $log4netLogger.error("The main module > $mainModuleName was not returned properly. Result > Failed to register that an update cycle ran. Value of MainModule.Modulebase > $($MainModule.ModuleBase)")
                }
            }
        }
    }
}