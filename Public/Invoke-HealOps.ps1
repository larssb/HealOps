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
        <none>
    .EXAMPLE
        Invoke-HealOps -TestsFileName Citrix.Services.ps1 -HealOpsPackage Citrix.HealOpsPackage
        Executes HealOps on a specific *.Tests.ps1 file. Sending in the HealOps package config file wherein HealOps will read configuration and tags.
    .PARAMETER HealOpsPackageName
        The name of the HealOps package that the TestsFileName belong to.
    .PARAMETER TestsFileName
        The name of the *.Tests.ps1 file to execute. The testsfile is part of the HealOps package specified with the HealOpsPackageName.
    .PARAMETER ForceUpdates
        Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.
    #>

        # Define parameters
        [CmdletBinding()]
        [OutputType([Void])]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars","")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
        param(
            [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The name of the HealOps package that the TestsFileName belong to.")]
            [ValidateNotNullOrEmpty()]
            [String]$HealOpsPackageName,
            [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The name of the *.Tests.ps1 file to execute. Relative to the HealOps package.")]
            [ValidateNotNullOrEmpty()]
            [String]$TestsFileName,
            [Parameter(Mandatory=$false, ParameterSetName="File", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
            [Parameter(Mandatory=$false, ParameterSetName="UpdateOnly", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
            [Switch]$ForceUpdates
        )

        #############
        # Execution #
        #############
        Begin {
            <#
                - Configure logging
            #>
            # Define log4net variables
            $log4NetConfigName = "HealOps.Log4Net"
            $log4netPath = "$PSScriptRoot/../Artefacts"

            # Initiate the log4net logger
            if($PSCmdlet.ParameterSetName -eq "File") {
                $logfileName_GeneratedPart = (Split-Path -Path $TestsFileName -Leaf) -replace ".ps1",""
            } else {
                $logfileName_GeneratedPart = "ForceUpdates"
            }
            $global:log4netLogger = initialize-log4net -log4NetPath $log4netPath -configFileName $log4NetConfigName -logfileName "HealOps.$logfileName_GeneratedPart" -loggerName "HealOps_Error"
            $global:log4netLoggerDebug = initialize-log4net -log4NetPath $log4netPath -configFileName $log4NetConfigName -logfileName "HealOps.$logfileName_GeneratedPart" -loggerName "HealOps_Debug"

            # Make the log more viewable.
            $log4netLoggerDebug.debug("--------------------------------------------------")
            $log4netLoggerDebug.debug("------------- HealOps logging started ------------")
            $log4netLoggerDebug.debug("------------- $((get-date).ToString()) -----------")
            $log4netLoggerDebug.debug("--------------------------------------------------")

            <#
                - CONSTANTS
            #>
            if ($PSCmdlet.ParameterSetName -eq "File") {
                # Constant for reporting on Repair status of "X" component og an IT service.
                New-Variable -Name repairSuccessValue -Value 1 -Option Constant -Description "Represent truthy in relation to the result of repairing 'X' component of an IT service" `
                -Visibility Private -Scope Script
                New-Variable -Name repairFailedValue -Value 0 -Option Constant -Description "Represent falsy in relation to the result of repairing 'X' component of an IT service" `
                -Visibility Private -Scope Script
            }

            <#
                - Sanity tests
            #>
            $HealOpsConfigPath = "$PSScriptRoot/../Artefacts/HealOpsConfig.json"
            if(-not (Test-Path -Path $HealOpsConfigPath)) {
                $message = "The file > $HealOpsConfigPath cannot be found. Please provide a HealOpsConfig.json file."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit
                throw $_
            } else {
                # Check file integrity & get config data
                $healOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
                if ($null -eq $healOpsConfig) {
                    $message = "The HealOpsConfig contains no data. Please generate a proper HealOpsConfig file. See the documentation."
                    Write-Verbose -Message $message

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $_
                } elseif(-not ($healOpsConfig.reportingBackend.Length -gt 1)) {
                    $message = "The HealOps config file is invalid. Please generate a proper HealOpsConfig file. See the documentation."
                    Write-Verbose -Message $message

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $_
                }
            }

            if ($PSCmdlet.ParameterSetName -eq "File") {
                <#
                    - Determine HealOps package related values
                #>
                # Latest version of the HealOps package locally
                try {
                    $latestHealOpsPackage = Get-LatestModuleVersionLocally -ModuleName $HealOpsPackageName
                } catch {
                    # Log it
                    $log4netLogger.error("$_")

                    # Exit
                    throw $_
                }

                # Get the testsfile named $TestsFileName
                try {
                    # Control if the value of $TestsFileName include the proper extension. To support that specifying the TestsFile with or without an extension.
                    $TestsFileNameExt = [System.IO.Path]::GetExtension($TestsFileName)
                    if (-not ($TestsFileNameExt -match ".ps1") ) {
                        $TestsFileName = "$TestsFileName.ps1"
                    }

                    # Get the TestsFile specified named as in $TestsFileNam
                    $TestsFile = Get-ChildItem -Path $latestHealOpsPackage.ModuleBase -Include $TestsFileName -Recurse -ErrorAction Stop

                    # Control that the TestsFile was found
                    if ($null -eq $TestsFile) {
                        $message = "No TestsFile named $TestsFileName was found. HealOps cannot continue."

                        # Log it
                        $log4netLogger.error("$message")

                        # Exit
                        throw $message
                    }
                } catch {
                    $message = "Getting the TestsFile named $TestsFileName in the HealOps package named $HealOpsPackageName failed with > $_"

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $message
                }

                # Control the config file in the HealOps package
                try {
                    $HealOpsPackageConfigFile = Get-ChildItem -Path $latestHealOpsPackage.ModuleBase -Include *.json -Recurse -ErrorAction Stop
                } catch {
                    $message = "Getting the HealOps package config json file failed with > $_"
                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $message
                }

                if($HealOpsPackageConfigFile.count -eq 1) {
                    # Check file integrity & get config data
                    $global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigFile.FullName -Encoding UTF8 | ConvertFrom-Json
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
            }

            <#
                - General module runtime config
            #>
            # Handle verbosity
            $commonParms = @{}
            if ($PSBoundParameters.ContainsKey("Verbose")) {
                $commonParms.Add("Verbose",$true)
            } else {
                $commonParms.Add("Verbose",$false)
            }

            <#
                - Check for updates. For the modules that HealOps has a dependency on and for HealOps itself
            #>
            $timeForUpdate = Confirm-TimeToUpdate -Config $HealOpsConfig
            if ($timeForUpdate -eq $true -or $ForceUpdates -eq $true) {
                # Run an update cycle on HealOps itself
                $HealOpsModuleName = "HealOps"
                Start-UpdateCycle -ModuleName $HealOpsModuleName -Config $healOpsConfig

                if ($ForceUpdates) {
                    # All installed HealOps packages.
                    try {
                        # Get HealOps packages installed
                        $InstalledHealOpsPackages = Get-Module -Name *HealOpsPackage* -ListAvailable -ErrorAction Stop
                    } catch {
                        $log4netLoggerDebug.error("Getting the installed HealOps packages failed with > $_")
                    }

                    if ($null -ne $InstalledHealOpsPackages) {
                        # Only 1 HealOpsPackage version per installed HealOps package.
                        $FilteredInstalledHealOpsPackages = $InstalledHealOpsPackages | Select-Object -Unique

                        # Iterate over each HealOps package installed on the system and call Start-UpdateCycle
                        foreach ($installedHealOpsPackage in $FilteredInstalledHealOpsPackages) {
                            Start-UpdateCycle -ModuleName $installedHealOpsPackage.Name -Config $healOpsConfig
                        }
                    } else {
                        $log4netLoggerDebug.debug("No HealOps packages found on the system. Searched on > '*HealOpsPackage*'")
                    }
                } else {
                    # Run an update cycle on the HealOps package that the TestsFile is a memberOf
                    Start-UpdateCycle -ModuleName $latestHealOpsPackage.Name -Config $healOpsConfig
                }

                # Debug info - register that forceupdate was used.
                if ($ForceUpdates -eq $true) {
                    $log4netLoggerDebug.debug("The force update paramater was used.")
                }
            } else {
                # The update cycle did not run.
                $log4netLoggerDebug.debug("The update cycle did not run. It is not the time for updating.")
                Write-Verbose -Message "The update cycle did not run. It is not the time for updating."
            }
        }
        Process {
            if ($PSCmdlet.ParameterSetName -eq "File") {
                # Test execution
                Write-Verbose -Message "Executing the test"
                try {
                    $testResult = Test-EntityState -TestFilePath $TestsFile.FullName -ErrorAction Stop
                } catch {
                    # Log it
                    $log4netLogger.error("Test-EntityState failed with: $_")
                }

                if ($testResult.state -eq $false) {
                    ###################
                    # The test failed #
                    ###################
                    Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                    try {
                        # Invoke repairs matching the failed test
                        $resultOfRepair = Repair-EntityState -TestFilePath $TestsFile.FullName -TestData $testResult.testdata -ErrorAction Stop @commonParms
                    } catch {
                        # Log it
                        $log4netLogger.error("Repair-EntityState failed with: $_")
                    }

                    if ($resultOfRepair -eq $false) {
                        # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                        try {
                            # Report the value of the failing component
                            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage) -ErrorAction Stop

                            # Report that the repair failed on the component
                            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -RepairMetricValue $repairFailedValue -ErrorAction Stop
                        } catch {
                            # TODO: LOG IT and inform x
                            $log4netLogger.error("Submit-EntityStateReport failed with: $_")
                            Write-Verbose "Submit-EntityStateReport failed with: $_"
                        }
                    } else {
                        try {
                            # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                            $testResult = Test-EntityState -TestFilePath $TestsFile.FullName -ErrorAction Stop
                        } catch {
                            # Log it
                            $log4netLogger.error("Test-EntityState failed with: $_")
                        }

                        # Test on the result in order to get correct data for the metric value.
                        if ($testResult.state -eq $true) {
                            if ((Get-Variable -Name passedTestResult -ErrorAction SilentlyContinue)) {
                                $metricValue = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                                $log4netLoggerDebug.debug("passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestsFileName")
                                Write-Verbose -Message "passedTestResult > $passedTestResult"
                            } else {
                                # TODO: Log IT and inform x!
                                $metricValue = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                                $log4netLogger.error("The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFileName <- this HAS to be done.")
                                Write-Verbose -Message "The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFileName <- this HAS to be done."
                            }
                        } else {
                            $metricValue = $($testResult.testdata.FailureMessage)
                        }

                        # Report the result
                        try {
                            # Report the value of the okay component after repairing it
                            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue -ErrorAction Stop

                            # Report that the repair succeeded on the component
                            Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -RepairMetricValue $repairSuccessValue -ErrorAction Stop
                        } catch {
                            # TODO: LOG IT and inform x
                            $log4netLogger.error("Submit-EntityStateReport failed with: $_")
                            Write-Verbose "Submit-EntityStateReport failed with: $_"
                        }
                    }
                } else {
                    ######################
                    # The test succeeded #
                    ######################
                    if ((Get-Variable -Name passedTestResult -ErrorAction SilentlyContinue)) {
                        $metricValue = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                        $log4netLoggerDebug.debug("passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestsFileName")
                        Write-Verbose -Message "passedTestResult > $passedTestResult"
                    } else {
                        # TODO: Log IT and inform x!
                        $metricValue = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                        $log4netLogger.error("The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFileName <- this HAS to be done.")
                        Write-Verbose -Message "The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFileName <- this HAS to be done."
                    }

                    # Report the state of the service to the backend report system.
                    try {
                        # Report the value of the okay component
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue -ErrorAction Stop
                    } catch {
                        # TODO: LOG IT and inform x
                        $log4netLogger.error("Submit-EntityStateReport failed with: $_")
                        Write-Verbose "Submit-EntityStateReport failed with: $_"
                    }
                }
            } # End of conditional check on ParameterSetName -eq "File"
        } # End of Process {} declaration
        End {}
    }