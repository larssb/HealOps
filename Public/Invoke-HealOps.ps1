function Invoke-HealOps() {
<#
.DESCRIPTION
    Invoke-HealOps is the function you call to initiate a HealOps package. Thereby testing "X" IT service/Entity.
    Where "X" can be n+m.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    Invoke-HealOps -TestFilePath $TestsFile -HealOpsPackageConfigPath $HealOpsPackageConfigPath
    Executes HealOps on a specific *.Tests.ps1 file. Sending in the HealOps package config file wherein HealOps will read configuration and tags.
.EXAMPLE
    Invoke-HealOps -TestsFilesRootPath "PATH_TO_THE_TESTS_REPAIRS_FOLDER" -HealOpsPackageConfigPath "PATH_TO_THE_HEALOPSCONFIGPATH"
    Will execute all the tests files located in the TestsFilesRootPath folder and HealOps will react on the result of executing these
.PARAMETER TestsFilesRootPath
    The folder that contains the tests to execute.
.PARAMETER HealOpsPackageConfigPath
    The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.
.PARAMETER TestsFile
    The full path to a specific *.Tests.ps1 file to execute.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars","")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Path", HelpMessage="The folder that contains the tests to execute.")]
        [ValidateNotNullOrEmpty()]
        [string]$TestsFilesRootPath,
        [Parameter(Mandatory=$true, ParameterSetName="Path", HelpMessage="The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.")]
        [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.")]
        [ValidateNotNullOrEmpty()]
        [string]$HealOpsPackageConfigPath,
        [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The full path to a specific *.Tests.ps1 file to execute.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsFile,
        [Parameter(Mandatory=$false, ParameterSetName="Path", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
        [Parameter(Mandatory=$false, ParameterSetName="File", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
        [Switch]$ForceUpdates
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Config logging
        #>
        # Define log4net variables
        $log4NetFilesName = "HealOps.Log4Net"

        # Initiate the log4net logger
        $log4netPath = "$PSScriptRoot/../Artefacts"
        $global:log4netLogger = initialize-log4net -log4NetFilesPath $log4netPath -log4NetFilesName $log4NetFilesName -log4NetLoggerName "HealOps_Error"
        $global:log4netLoggerDebug = initialize-log4net -log4NetFilesPath $log4netPath -log4NetFilesName $log4NetFilesName -log4NetLoggerName "HealOps_Debug"

        # Make the log more viewable.
        $log4netLoggerDebug.debug("--------------------------------------------------")
        $log4netLoggerDebug.debug("------------- HealOps logging started ------------")
        $log4netLoggerDebug.debug("------------- $((get-date).ToString()) -----------")
        $log4netLoggerDebug.debug("--------------------------------------------------")

        <#
            - Sanity tests
        #>
        if($PSBoundParameters.ContainsKey('TestsFilesRootPath')) {
            if (-not (Test-Path -Path $TestsFilesRootPath)) {
                $message = "The path > $TestsFilesRootPath is invalid. Please provide an existing folder."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
                throw $message
            }
        }

        if($PSBoundParameters.ContainsKey('TestsFile')) {
            if(-not (Test-Path -Path $TestsFile)) {
                $message = "The file > $TestsFile cannot be found. Please provide a *.Tests.ps1 file that exists."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
                throw $message
            }
        }

        $HealOpsConfigPath = "$PSScriptRoot/../Artefacts/HealOpsConfig.json"
        if(-not (Test-Path -Path $HealOpsConfigPath)) {
            $message = "The file > $HealOpsConfigPath cannot be found. Please provide a HealOpsConfig.json file."
            Write-Verbose -Message $message

            # Log it
            $log4netLogger.error("$message")

            # Exit by throwing
            throw $message
        } else {
            # Check file integrity & get config data
            $healOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $healOpsConfig) {
                $message = "The HealOpsConfig contains no date. Please generate a proper HealOpsConfig file. See the documentation and generate a proper one."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
                throw $message
            } elseif(-not ($healOpsConfig.reportingBackend.Length -gt 1)) {
                $message = "The HealOpsConfig file is not valid. Please generate a proper HealOpsConfig file. See the documentation and generate a proper one."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
                throw $message
            }
        }

        if(-not (Test-Path -Path $HealOpsPackageConfigPath)) {
            $message = "The file > $HealOpsPackageConfigPath cannot be found. Please provide a HealOps package config file that exists."
            Write-Verbose -Message $message

            # Log it
            $log4netLogger.error("$message")

            # Exit by throwing
            throw $message
        } else {
            # Check file integrity & get config data
            $global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigPath -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $HealOpsPackageConfig) {
                $message = "The HealOps package config contains no date. Please provide a proper HealOps package config file."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
                throw $message
            } elseif($null -eq $HealOpsPackageConfig[0]) {
                $message = "The HealOps package config file is not valid. Please provide a proper one."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit by throwing
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
        if ($healOpsConfig.checkForUpdates -eq "True" -or $ForceUpdates -eq $true) {
            $HealOpsModuleName = "HealOps"
            $updateCycleRan = $false # Semaphore from which to determine if an update cycle ran or not.
            if ($healOpsConfig.checkForUpdatesNext.length -le 2) {
                <#
                    - checkForUpdatesNext not correctly defined in the HealOps config json file or not defined at all. Assumption > check for updates now.
                #>
                Write-Verbose -Message "checkForUpdatesNext not correctly defined in the HealOps config json."

                # Get modules required by HealOps - As we are in the HealOps module itself, we know that HealOps is installed ;-)
                $HealOpsModule = Get-Module -All -Name $HealOpsModuleName
                foreach ($requiredModule in $HealOpsModule.RequiredModules) {
                    # Register the current version of the module
                    $moduleVersionBeforeUpdate = $requiredModule.version

                    try {
                        # Update
                        Update-Module -Name $requiredModule.Name -ErrorAction Stop -ErrorVariable updateModuleEV
                    } catch {
                        # Log it - To the Reporting backend???
                        $log4netLogger.error("Updating the module $($requiredModule.Name) failed with > $_")

                        # When in verbose mode
                        Write-Verbose -Message "Updating the module $($requiredModule.Name) failed with > $_"
                    }

                    if ($null -eq $updateModuleEV) {
                        $updateRan = $true
                    } else {
                        $updateRan = $false
                    }

                    # Control if the module was actually updated after a non-terminating update-module execution
                    if ($updateRan -eq $true) {
                        Test-ModuleUpdated -ModuleName $requiredModule.Name -ModuleVersionBeforeUpdate $moduleVersionBeforeUpdate @commonParms
                    }
                }

                # Check for updates to HealOps itself.
                try {
                    # Update
                    Update-Module -Name $HealOpsModuleName -ErrorAction Stop -ErrorVariable updateModuleEV
                } catch {
                    # Log it - To the Reporting backend???
                    $log4netLogger.error("Updating the module $HealOpsModuleName failed with > $_")

                    # When in verbose mode
                    Write-Verbose -Message "Updating the module $HealOpsModuleName failed with > $_"
                }

                if ($null -eq $updateModuleEV) {
                    $updateRan = $true
                } else {
                    $updateRan = $false
                }

                # Control if the module was actually updated after a non-terminating update-module execution
                if ($updateRan -eq $true) {
                    Test-ModuleUpdated -ModuleName $requiredModule.Name -ModuleVersionBeforeUpdate $moduleVersionBeforeUpdate @commonParms
                }

                # The update cycle ran
                $updateCycleRan = $true
            } else {
                # checkedForUpdates properly defined. Control the date of the last update and hold it up against checkForUpdatesNext
                $currentDate = get-date
                $checkForUpdatesNext = $healOpsConfig.checkForUpdatesNext -as [datetime]

                if ($currentDate -gt $checkForUpdatesNext) {
                    # Get modules required by HealOps - As we are in the HealOps module itself, we know that HealOps is installed ;-)
                    $HealOpsModule = Get-Module -All -Name $HealOpsModuleName

                    # We should update
                    foreach ($requiredModule in $HealOpsModule.RequiredModules) {
                        # Register the current version of the module
                        $moduleVersionBeforeUpdate = $requiredModule.version

                        try {
                            # Update
                            Update-Module -Name $requiredModule.Name -ErrorAction Stop -ErrorVariable updateModuleEV
                        } catch {
                            # Log it
                            $log4netLogger.error("Updating the module $($requiredModule.Name) failed with > $_")

                            # When in verbose mode
                            Write-Verbose -Message "Updating the module $($requiredModule.Name) failed with > $_"
                        }

                        if ($null -eq $updateModuleEV) {
                            $updateRan = $true
                        } else {
                            $updateRan = $false
                        }

                        # Control if the module was actually updated after a non-terminating update-module execution
                        if ($updateRan -eq $true) {
                            Test-ModuleUpdated -ModuleName $requiredModule.Name -ModuleVersionBeforeUpdate $moduleVersionBeforeUpdate @commonParms
                        }
                    }

                    # Check for updates to HealOps itself.
                    try {
                        # Update
                        Update-Module -Name $HealOpsModuleName -ErrorAction Stop -ErrorVariable updateModuleEV
                    } catch {
                        # Log it - To the Reporting backend???
                        $log4netLogger.error("Updating the module $HealOpsModuleName failed with > $_")

                        # When in verbose mode
                        Write-Verbose -Message "Updating the module $HealOpsModuleName failed with > $_"
                    }

                    if ($null -eq $updateModuleEV) {
                        $updateRan = $true
                    } else {
                        $updateRan = $false
                    }

                    # Control if the module was actually updated after a non-terminating update-module execution
                    if ($updateRan -eq $true) {
                        Test-ModuleUpdated -ModuleName $requiredModule.Name -ModuleVersionBeforeUpdate $moduleVersionBeforeUpdate @commonParms
                    }

                    # The update cycle ran
                    $updateCycleRan = $true
                }
            }

            # Check if an update cycle was ran and set data in order to register the fact
            if ($updateCycleRan) {
                <#
                - The update cycle ran. Determine the time for the next update cycle
                #>
                # Determine DateTime for checkForUpdatesNext. Using a random plus "M" minutes, in order to NOT overload the Package Management backend with requests at the same time. In this way package request will be more evenly spread out.
                $checkForUpdatesNext_DateTimeRandom = get-random -Minimum 1 -Maximum 123
                if ($healOpsConfig.checkForUpdatesInterval_InDays.length -ge 1) {
                    # Use the interval from the HealOps config json file.
                    $checkForUpdatesNext = (get-date).AddDays($healOpsConfig.checkForUpdatesInterval_InDays).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
                } else {
                    # Fall back to a default interval of 1 day.
                    $checkForUpdatesNext = (get-date).AddDays(1).AddMinutes(($checkForUpdatesNext_DateTimeRandom)).ToString()
                }
            } else {
                # The update cycle did not run. It could have failed or the time criteria was not met. Set to the same time of checkForUpdatesNext > in order to have HealOps run an update cycle again.
                $checkForUpdatesNext = $healOpsConfig.checkForUpdatesNext
                $log4netLoggerDebug.debug("The update cycle did not run. It is not the time for updating.")
                Write-Verbose -Message "The update cycle did not run. It is not the time for updating."
            }

            # When in verbose mode
            Write-Verbose -Message "The value of checkForUpdatesNext > $checkForUpdatesNext"
            $log4netLoggerDebug.debug("The value of checkForUpdatesNext > $checkForUpdatesNext")
        } # End of condition control on the checkForUpdates feature is enabled or forced
    }
    Process {
        if ($PSBoundParameters.ContainsKey('TestsFilesRootPath')) {
            # Get the *.Tests.ps1 files in the provided directory
            $TestsFiles = Get-ChildItem -Path $TestsFilesRootPath -Recurse -Force -Include "*.Tests.ps1"
            Write-Verbose -Message "We got the following test files: $TestsFiles"

            foreach ($testfile in $TestsFiles) {
                # Control if "X" tests is already running. If so == do not execute the test
                try {
                    $testRunning = Test-RunningTest -TestFileName $testfile.name -TestsFilesRootPath $TestsFilesRootPath @commonParms
                } catch {
                    # Log it
                    $log4netLogger.error("MODE: TestsFilesRootPath | Test-RunningTest failed with: $_")
                    throw "The function Test-RunningTest failed with: $_"
                }

                # Execute the test if it isn't already running
                if ($testRunning -eq $false) {
                    # Support a relative paths for the TestsFilesRootPath parameter
                    if ( ([System.IO.Path]::IsPathRooted("$TestsFilesRootPath") -eq $false) ) {
                        # The path is relative. Resolve it to an absolute path. Relative to PWD before start-job runs per job.
                        [System.IO.Directory]::SetCurrentDirectory($(get-location)) # To set the resolve directory ::GetFullPath() will use. This will SetCurrentDirectory to $PWD. If not done [System.IO.Path] picks up the PowerShell shell's current directory which per default is $HOME & not $PWD
                        $TestsFilesRootPath = [System.IO.Path]::GetFullPath("$TestsFilesRootPath")
                        $log4netLoggerDebug.debug("Resolved TestsFilesRootPath path > $TestsFilesRootPath")
                        Write-Verbose -Message "Resolved TestsFilesRootPath path > $TestsFilesRootPath"
                    }

                    # Update the test *.Status.json file to reflect that the test is NOW running
                    try {
                        Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $testfile.name -TestRunning @commonParms
                    } catch {
                        # Log it
                        $log4netLogger.error("MODE: TestsFilesRootPath | Update-TestRunningStatus failed with: $_")
                        throw $_
                    }

                    # Start a job per test.
                    $job = Start-Job -Name "HealOps-TestAndRepair-$($testfile.name)" -Verbose -ScriptBlock {
                        #########################
                        # Start-Job ScriptBlock #
                        #########################
                        param($TestsFilesRootPath,$commonParms,$HealOpsPackageConfig,$PSScriptRoot,$log4netPath)
                        # Import modules
                        . $PSScriptRoot/../Private/Test-EntityState.ps1
                        . $PSScriptRoot/../Private/JobHandling/Update-TestRunningStatus.ps1
                        . $PSScriptRoot/../Private/Repair-EntityState.ps1
                        . $PSScriptRoot/../Private/Submit-EntityStateReport.ps1

                        <#
							- Configure logging
						#>
						# Initiate the log4net logger
						$global:log4netLogger = initialize-log4net -log4NetFilesPath $log4netPath -log4NetFilesName "HealOps.Jobs.Log4Net" -log4NetLoggerName "HealOps_Error_Job"
						$global:log4netLoggerDebug = initialize-log4net -log4NetFilesPath $log4netPath -log4NetFilesName "HealOps.Jobs.Log4Net" -log4NetLoggerName "HealOps_Debug_Job"

                        try {
                            # Test execution
                            $testResult = Test-EntityState -TestFilePath $using:testfile.FullName
                        } catch {
                            # Log it
                            $log4netLogger.error("MODE: TestsFilesRootPath | Test-EntityState failed with: $_")
                            throw $_
                        }

                        # Update the test *.Status.json file to reflect that the test is NO longer running
                        try {
                            Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $using:testfile.name @commonParms
                        } catch {
                            # Log it
                            $log4netLogger.error("MODE: TestsFilesRootPath | In Job | Update-TestRunningStatus failed with: $_")
                            throw $_
                        }

                        if ($testResult.state -eq $false) {
                            ###################
                            # The test failed #
                            ###################
                            Write-Verbose -Message "Trying to repair the 'Failed' test/s."
                            try {
                                # Invoke repairs matching the failed test
                                $resultOfRepair = Repair-EntityState -TestFilePath $using:testfile.FullName -TestData $testResult.testdata @commonParms
                            } catch {
                                # Log it
                                $log4netLogger.error("MODE: TestsFilesRootPath | Repair-EntityState failed with: $_")
                                throw $_
                            }

                            if ($resultOfRepair -eq $false) {
                                # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                                try {
                                    Submit-EntityStateReport -reportBackendSystem $($using:healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage)
                                } catch {
                                    # TODO: LOG IT and inform x
                                    $log4netLogger.error("MODE: TestsFilesRootPath | Submit-EntityStateReport failed with: $_")
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"
                                    throw $_
                                }
                            } else {
                                try {
                                    # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                                    $testResult = Test-EntityState -TestFilePath $using:testfile.FullName
                                } catch {
                                    # Log it
                                    $log4netLogger.error("MODE: TestsFilesRootPath | Test-EntityState failed with: $_")
                                    throw $_
                                }

                                # Update the test *.Status.json file to reflect that the test is NO longer running
                                try {
                                    Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $using:testfile.name @commonParms
                                } catch {
                                    # Log it
                                    $log4netLogger.error("MODE: TestsFilesRootPath | In Job | Update-TestRunningStatus failed with: $_")
                                    throw $_
                                }

                                # Test on the result in order to get correct data for the metric value.
                                if ($testResult.state -eq $true) {
                                    $metricValue = $assertionResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                                    $log4netLoggerDebug.debug("assertionResult value > $assertionResult set in *.Tests.ps1 file > $($using:testfile.Name)")
                                    Write-Verbose -Message "assertionResult > $assertionResult"
                                } else {
                                    $metricValue = $($testResult.testdata.FailureMessage)
                                }

                                # Report the result
                                try {
                                    Submit-EntityStateReport -reportBackendSystem $($using:healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue
                                } catch {
                                    # TODO: LOG IT and inform x
                                    $log4netLogger.error("MODE: TestsFilesRootPath | Submit-EntityStateReport failed with: $_")
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"
                                    throw $_
                                }
                            }
                        } else {
                            ######################
                            # The test succeeded #
                            ######################
                            if ((Get-Variable -Name assertionResult)) {
                                # Report the state of the service to the backend report system.
                                try {
                                    Submit-EntityStateReport -reportBackendSystem $($using:healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $assertionResult
                                } catch {
                                    # TODO: LOG IT and inform x
                                    $log4netLogger.error("MODE: TestsFilesRootPath | Submit-EntityStateReport failed with: $_")
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"
                                    throw $_
                                }
                            } else {
                                # TODO: Log IT and inform x!
                                $log4netLogger.error("The assertionResult variable was not defined in the *.Tests.ps1 file > $($using:testfile.Name) <- this HAS to be done.")
                                Write-Verbose -Message "The assertionResult variable was not defined in the *.Tests.ps1 file > $($using:testfile.Name) <- this HAS to be done."
                            }
                        }
                    } -ArgumentList $TestsFilesRootPath,$commonParms,$HealOpsPackageConfig,$PSScriptRoot,$log4netPath
                }
            } # End of foreach tests file in $TestsFilesRootPath
        } elseif ($PSBoundParameters.ContainsKey('TestsFile')) {
            # Test execution
            Write-Verbose -Message "Executing the test"
            try {
                $testResult = Test-EntityState -TestFilePath $TestsFile
            } catch {
                # Log it
                $log4netLogger.error("MODE: TestsFile | Test-EntityState failed with: $_")
                throw $_
            }

            if ($testResult.state -eq $false) {
                ###################
                # The test failed #
                ###################
                Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                try {
                    # Invoke repairs matching the failed test
                    $resultOfRepair = Repair-EntityState -TestFilePath $TestsFile -TestData $testResult.testdata @commonParms
                } catch {
                    # Log it
                    $log4netLogger.error("MODE: TestsFile | Repair-EntityState failed with: $_")
                    throw $_
                }

                if ($resultOfRepair -eq $false) {
                    # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage)
                    } catch {
                        # TODO: LOG IT and inform x
                        $log4netLogger.error("MODE: TestsFile | Submit-EntityStateReport failed with: $_")
                        Write-Verbose "Submit-EntityStateReport failed with: $_"
                    }
                } else {
                    try {
                        # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                        $testResult = Test-EntityState -TestFilePath $TestsFile
                    } catch {
                        # Log it
                        $log4netLogger.error("MODE: TestsFile | Test-EntityState failed with: $_")
                        throw $_
                    }

                    # Test on the result in order to get correct data for the metric value.
                    if ($testResult.state -eq $true) {
                        $metricValue = $assertionResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                        $log4netLoggerDebug.debug("assertionResult value > $assertionResult set in *.Tests.ps1 file > $TestsFile)")
                        Write-Verbose -Message "assertionResult > $assertionResult"
                    } else {
                        $metricValue = $($testResult.testdata.FailureMessage)
                    }

                    # Report the result
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue
                    } catch {
                        # TODO: LOG IT and inform x
                        $log4netLogger.error("MODE: TestsFile | Submit-EntityStateReport failed with: $_")
                        Write-Verbose "Submit-EntityStateReport failed with: $_"
                        throw $_
                    }
                }
            } else {
                ######################
                # The test succeeded #
                ######################
                if ((Get-Variable -Name assertionResult)) {
                    # Report the state of the service to the backend report system.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $assertionResult
                    } catch {
                        # TODO: LOG IT and inform x
                        $log4netLogger.error("MODE: TestsFile | Submit-EntityStateReport failed with: $_")
                        Write-Verbose "Submit-EntityStateReport failed with: $_"
                    }
                } else {
                    # TODO: Log IT and inform x!
                    $log4netLogger.error("The assertionResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done.")
                    Write-Verbose -Message "The assertionResult variable was NOT defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                    throw $_
                }
            }
        }
    }
    End {
        # Update the HealOps config json file
        $healOpsConfig.checkForUpdatesNext = $checkForUpdatesNext

        # Convert the JSON
        $healOpsConfigInJSON = ConvertTo-Json -InputObject $healOpsConfig -Depth 3

        # Update the HealOps config json file
        try {
            Set-Content -Path $HealOpsConfigPath -Value $healOpsConfigInJSON -Force -Encoding UTF8
        } catch {
            # Log it
            $log4netLogger.error("Failed to write the HealOps config json file. Failed with > $_")
            throw "Failed to write the HealOps config json file. Failed with > $_"
        }
    }
}