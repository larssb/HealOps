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
        [String]$TestsFile
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Sanity tests
        #>
        if($PSBoundParameters.ContainsKey('TestsFilesRootPath')) {
            if (-not (Test-Path -Path $TestsFilesRootPath)) {
                $message = "The path > $TestsFilesRootPath is invalid. Please provide an existing folder."
                Write-Verbose -Message $message

                # Log it

                # Exit by throwing
                throw $message
            }
        }

        if($PSBoundParameters.ContainsKey('TestsFile')) {
            if(-not (Test-Path -Path $TestsFile)) {
                $message = "The file > $TestsFile cannot be found. Please provide a *.Tests.ps1 file that exists."
                Write-Verbose -Message $message

                # Log it

                # Exit by throwing
                throw $message
            }
        }

        $HealOpsConfigPath = "$PSScriptRoot/../Artefacts/HealOpsConfig.json"
        if(-not (Test-Path -Path $HealOpsConfigPath)) {
            $message = "The file > $HealOpsConfigPath cannot be found. Please provide a HealOpsConfig.json file."
            Write-Verbose -Message $message

            # Log it

            # Exit by throwing
            throw $message
        } else {
            # Check file integrity & get config data
            $healOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $healOpsConfig) {
                $message = "The HealOpsConfig contains no date. Please generate a proper HealOpsConfig file. See the documentation and generate a proper one."
                Write-Verbose -Message $message

                # Log it

                # Exit by throwing
                throw $message
            } elseif(-not ($healOpsConfig.reportingBackend.Length -gt 1)) {
                $message = "The HealOpsConfig file is not valid. Please generate a proper HealOpsConfig file. See the documentation and generate a proper one."
                Write-Verbose -Message $message

                # Log it

                # Exit by throwing
                throw $message
            }
        }

        if(-not (Test-Path -Path $HealOpsPackageConfigPath)) {
            $message = "The file > $HealOpsPackageConfigPath cannot be found. Please provide a HealOps package config file that exists."
            Write-Verbose -Message $message

            # Log it

            # Exit by throwing
            throw $message
        } else {
            # Check file integrity & get config data
            $global:HealOpsPackageConfig = Get-Content -Path $HealOpsPackageConfigPath -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $HealOpsPackageConfig) {
                $message = "The HealOps package config contains no date. Please provide a proper HealOps package config file."
                Write-Verbose -Message $message

                # Log it

                # Exit by throwing
                throw $message
            } elseif($null -eq $HealOpsPackageConfig[0]) {
                $message = "The HealOps package config file is not valid. Please provide a proper one."
                Write-Verbose -Message $message

                # Log it

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

                    throw "The function Test-RunningTest failed with: $_"
                }

                # Execute the test if it isn't already running
                if ($testRunning -eq $false) {
                    # Update the test *.Status.json file to reflect that the test is NOW running
                    try {
                        Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $testfile.name -TestRunning
                    } catch {
                        throw $_
                    }

                    # Start a job per test.
                    Write-Verbose -Message "Executing the test"
                    $job = Start-Job -Name "HealOps-TestAndRepair-$($testfile.name)" -InitializationScript (
                        ##################################
                        # Start-Job InitializationScript #
                        ##################################
                        [scriptblock]::Create(
                            "Set-Location $PSScriptRoot;
                            . $PSScriptRoot/../Private/Test-EntityState.ps1;
                            . $PSScriptRoot/../Private/JobHandling/Update-TestRunningStatus.ps1;
                            . $PSScriptRoot/../Private/Repair-EntityState.ps1;
                            . $PSScriptRoot/../Private/Submit-EntityStateReport.ps1;
                            Set-Location $PWD"
                        )
                    ) -ScriptBlock {
                        #########################
                        # Start-Job ScriptBlock #
                        #########################
                        param($TestsFilesRootPath,$commonParms,$HealOpsPackageConfig)

                        # Test execution
                        $testResult = Test-EntityState -TestFilePath $using:testfile.FullName

                        # Update the test *.Status.json file to reflect that the test is NO longer running
                        try {
                            Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $using:testfile.name
                        } catch {
                            throw $_
                        }

                        if ($testResult.state -eq $false) {
                            ###################
                            # The test failed #
                            ###################
                            Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                            # Invoke repairs matching the failed test
                            $resultOfRepair = Repair-EntityState -TestFilePath $using:testfile.FullName -TestData $testResult.testdata @commonParms

                            if ($resultOfRepair -eq $false) {
                                # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                                try {
                                    Submit-EntityStateReport -reportBackendSystem $($using:healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage)
                                } catch {
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"

                                    # TODO: LOG IT and inform x
                                }
                            } else {
                                # Run the *.Tests.ps1 file again to verify that repairing was successful and to get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.
                                $testResult = Test-EntityState -TestFilePath $using:testfile.FullName

                                # Test on the result in order to get correct data for the metric value.
                                if ($testResult.state -eq $true) {
                                    $metricValue = $assertionResult # Uses the global variable set in the *.Tests.ps1 file to capture a numeric value to report to the reporting backend.
                                } else {
                                    $metricValue = $($testResult.testdata.FailureMessage)
                                }

                                # Report the result
                                try {
                                    Submit-EntityStateReport -reportBackendSystem $($using:healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $metricValue
                                } catch {
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"

                                    # TODO: LOG IT and inform x
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
                                    Write-Verbose "Submit-EntityStateReport failed with: $_"

                                    # TODO: LOG IT and inform x
                                }
                            } else {
                                # TODO: Log IT and inform x!
                                Write-Verbose -Message "The assertionResult variable was not defined in the *.Tests.ps1 file > $($using:testfile.name) <- this HAS to be done."
                            }
                        }
                    } -Verbose -ArgumentList $TestsFilesRootPath,$commonParms,$HealOpsPackageConfig
                }
            } # End of foreach tests file in $TestsFilesRootPath
        } elseif ($PSBoundParameters.ContainsKey('TestsFile')) {
            # Test execution
            Write-Verbose -Message "Executing the test"
            $testResult = Test-EntityState -TestFilePath $TestsFile

            if ($testResult.state -eq $false) {
                ###################
                # The test failed #
                ###################
                Write-Verbose -Message "Trying to repair the 'Failed' test/s."

                # Invoke repairs matching the failed test
                $resultOfRepair = Repair-EntityState -TestFilePath $TestsFile -TestData $testResult.testdata @commonParms

                if ($resultOfRepair -eq $false) {
                    # Report the state of the service to the backend report system. Which should then further trigger an alarm to the on-call personnel.
                    try {
                        Submit-EntityStateReport -reportBackendSystem $($healOpsConfig.reportingBackend) -metric $($testResult.metric) -metricValue $($testResult.testdata.FailureMessage)
                    } catch {
                        Write-Verbose "Submit-EntityStateReport failed with: $_"

                        # TODO: LOG IT and inform x
                    }
                } else {
                    # Run the *.Tests.ps1 file again to verify and get data for reporting to the backend so that a monitored state of "X" IT service/Entity will get back to an okay state in the monitoring system.

                    # THINK THIS THROUGH!
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
                        Write-Verbose "Submit-EntityStateReport failed with: $_"

                        # TODO: LOG IT and inform x
                    }
                } else {
                    # TODO: Log IT and inform x!
                    Write-Verbose -Message "The assertionResult variable was not defined in the *.Tests.ps1 file > $TestFilePath <- this HAS to be done."
                }
            }
        }
    }
    End {}
}