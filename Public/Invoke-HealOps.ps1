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
        Invoke-HealOps -TestsFile $TestsFile -HealOpsPackageConfigPath $HealOpsPackageConfigPath
        Executes HealOps on a specific *.Tests.ps1 file. Sending in the HealOps package config file wherein HealOps will read configuration and tags.
    .PARAMETER HealOpsPackageConfigPath
        The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.
    .PARAMETER TestsFile
        The full path to a specific *.Tests.ps1 file to execute.
    .PARAMETER ForceUpdates
        Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.
    #>

        # Define parameters
        [CmdletBinding()]
        [OutputType([Void])]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars","")]
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
        param(
            [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The path to a JSON file containing settings and tag value data for reporting. Relative to a specific HealOpsPackage.")]
            [ValidateNotNullOrEmpty()]
            [string]$HealOpsPackageConfigPath,
            [Parameter(Mandatory=$true, ParameterSetName="File", HelpMessage="The full path to a specific *.Tests.ps1 file to execute.")]
            [ValidateNotNullOrEmpty()]
            [String]$TestsFile,
            [Parameter(Mandatory=$false, ParameterSetName="File", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
            [Parameter(Mandatory=$false, ParameterSetName="UpdateOnly", HelpMessage="Use this switch parameter to force an update of HealOps and its pre-requisites regardless of the values in the HealOps config json file.")]
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
            $log4NetConfigName = "HealOps.Log4Net"
            $log4netPath = "$PSScriptRoot/../Artefacts"

            # Initiate the log4net logger
            $TestsFileRootName = (Split-Path -Path $TestsFile -Leaf) -replace ".ps1",""
            $global:log4netLogger = initialize-log4net -log4NetPath $log4netPath -configFileName $log4NetConfigName -logfileName "HealOps.Main.$TestsFileRootName" -loggerName "HealOps_Error"
            $global:log4netLoggerDebug = initialize-log4net -log4NetPath $log4netPath -configFileName $log4NetConfigName -logfileName "HealOps.Main.$TestsFileRootName" -loggerName "HealOps_Debug"

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

                    # Exit
                    throw $_
                }
            }

            if($PSBoundParameters.ContainsKey('TestsFile')) {
                if(-not (Test-Path -Path $TestsFile)) {
                    $message = "The file > $TestsFile cannot be found. Please provide a *.Tests.ps1 file that exists."
                    Write-Verbose -Message $message

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $_
                }
            }

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

            if(-not (Test-Path -Path $HealOpsPackageConfigPath)) {
                $message = "The file > $HealOpsPackageConfigPath cannot be found. Please provide a HealOps package config file that exists."
                Write-Verbose -Message $message

                # Log it
                $log4netLogger.error("$message")

                # Exit
                throw $_
            } else {
                # Check file integrity & get config data
                $global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigPath -Encoding UTF8 | ConvertFrom-Json
                if ($null -eq $HealOpsPackageConfig) {
                    $message = "The HealOps package config contains no data. Please provide a proper HealOps package config file."
                    Write-Verbose -Message $message

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $_
                } elseif($null -eq $HealOpsPackageConfig[0]) {
                    $message = "The HealOps package config file is not valid. Please provide a proper one."
                    Write-Verbose -Message $message

                    # Log it
                    $log4netLogger.error("$message")

                    # Exit
                    throw $_
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
                # Run an update cycle
                $HealOpsModuleName = "HealOps"
                Start-UpdateCycle -ModuleName $HealOpsModuleName -Config $healOpsConfig

                # Debug info - register that a forceupdate was done.
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
            # Test execution
            Write-Verbose -Message "Executing the test"
            try {
                $testResult = Test-EntityState -TestFilePath $TestsFile -ErrorAction Stop
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
                    $resultOfRepair = Repair-EntityState -TestFilePath $TestsFile -TestData $testResult.testdata -ErrorAction Stop @commonParms
                } catch {
                    # Log it
                    $log4netLogger.error("Repair-EntityState failed with: $_")
                }

                if ($resultOfRepair -eq $false) {
                    # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage) -ErrorAction Stop
                    } catch {
                        # TODO: LOG IT and inform x
                        $log4netLogger.error("Submit-EntityStateReport failed with: $_")
                        Write-Verbose "Submit-EntityStateReport failed with: $_"
                    }
                } else {
                    try {
                        # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                        $testResult = Test-EntityState -TestFilePath $TestsFile -ErrorAction Stop
                    } catch {
                        # Log it
                        $log4netLogger.error("Test-EntityState failed with: $_")
                    }

                    # Test on the result in order to get correct data for the metric value.
                    if ($testResult.state -eq $true) {
                        if ((Get-Variable -Name passedTestResult)) {
                            $metricValue = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                            $log4netLoggerDebug.debug("passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestsFile)")
                            Write-Verbose -Message "passedTestResult > $passedTestResult"
                        } else {
                            # TODO: Log IT and inform x!
                            $metricValue = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                            $log4netLogger.error("The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFile <- this HAS to be done.")
                            Write-Verbose -Message "The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFile <- this HAS to be done."
                        }
                    } else {
                        $metricValue = $($testResult.testdata.FailureMessage)
                    }

                    # Report the result
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue -ErrorAction Stop
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
                if ((Get-Variable -Name passedTestResult)) {
                    $metricValue = $passedTestResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                    $log4netLoggerDebug.debug("passedTestResult value > $passedTestResult set in *.Tests.ps1 file > $TestsFile)")
                    Write-Verbose -Message "passedTestResult > $passedTestResult"
                } else {
                    # TODO: Log IT and inform x!
                    $metricValue = -1 # Value indicating that the global variable passedTestResult was not set correctly in the *.Tests.ps1 file.
                    $log4netLogger.error("The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFile <- this HAS to be done.")
                    Write-Verbose -Message "The passedTestResult variable was NOT defined in the *.Tests.ps1 file > $TestsFile <- this HAS to be done."
                }

                # Report the state of the service to the backend report system.
                try {
                    Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue -ErrorAction Stop
                } catch {
                    # TODO: LOG IT and inform x
                    $log4netLogger.error("Submit-EntityStateReport failed with: $_")
                    Write-Verbose "Submit-EntityStateReport failed with: $_"
                }
            }
        }
        End {}
    }