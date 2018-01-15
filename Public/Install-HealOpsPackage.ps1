function Install-HealOpsPackage() {
<#
.DESCRIPTION
    Uses the self-update feature of HealOps to install the HealOps package or packages specified when calling this function.
.INPUTS
    [String] or [Array] reprsenting the HealOps package or packages to install on a system.
.OUTPUTS
    [Boolean] relative to the result of installing 'X' amount of HealOps packages.
.NOTES
    <none>
.EXAMPLE
    Install-HealOpsPackage -Package "Package.HealOpsPackage"
    Uses the self-update feature of HealOps to install the HealOps package or packages specified.
.PARAMETER AnonymousNotAllowed
    Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.
.PARAMETER APIKey
    The API key to used when communicatnig with the Package Management backend.
.PARAMETER FeedName
    The name of the feed on the Package Management backend, in which modules used by HealOps are stored.
.PARAMETER JobType
    The type of job to use when invoking HealOps.
.PARAMETER Package
    The name of a package or packages to install on a system.
        > [String[]]
.PARAMETER PackageManagementURI
    The URI of the Package Management backend, where modules used by HealOps are stored.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars","")]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="SelfUpdateDisabled", HelpMessage="Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.")]
        [Switch]$AnonymousNotAllowed,
        [Parameter(Mandatory=$true, ParameterSetName="SelfUpdateDisabled", HelpMessage="The API key to used when communicatnig with the Package Management backend.")]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,
        [Parameter(Mandatory=$true, ParameterSetName="SelfUpdateDisabled", HelpMessage="The name of the feed on the Package Management backend, in which modules used by HealOps are stored.")]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of job to use when invoking HealOps.")]
        [Parameter(Mandatory=$true, ParameterSetName="SelfUpdateDisabled", HelpMessage="The type of job to use when invoking HealOps.")]
        [ValidateSet('WinPSJob','WinScTask','LinCronJob')]
        [String]$JobType,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of a package or packages to install on a system.")]
        [Parameter(Mandatory=$true, ParameterSetName="SelfUpdateDisabled", HelpMessage="The name of a package or packages to install on a system.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Package,
        [Parameter(Mandatory=$true, ParameterSetName="SelfUpdateDisabled", HelpMessage="The URI of the Package Management backend, where modules used by HealOps are stored.")]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI
    )

    #############
    # Execution #
    #############
    Begin {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator");
        if (-not ($isAdmin)) {
            throw "You need to execute PowerShell as admin/sudo/root in order to Install HealOps."
        }

        <#
            - Configure logging
        #>
        # Define log4net variables
        $log4NetConfigFile = "$PSScriptRoot/../Artefacts/HealOps.Log4Net.xml"
        $LogFilesPath = "$PSScriptRoot/../Artefacts"

        # Initiate the log4net logger
        $global:log4netLogger = initialize-log4net -log4NetConfigFile $log4NetConfigFile -LogFilesPath $LogFilesPath -logfileName "InstallHealOpsPackage" -loggerName "HealOps_Error"
        $global:log4netLoggerDebug = initialize-log4net -log4NetConfigFile $log4NetConfigFile -LogFilesPath $LogFilesPath -logfileName "InstallHealOpsPackage" -loggerName "HealOps_Debug"

        # Make the log more viewable.
        $log4netLoggerDebug.debug("--------------------------------------------------")
        $log4netLoggerDebug.debug("------------- HealOps logging started ------------")
        $log4netLoggerDebug.debug("------------- $((get-date).ToString()) -----------")
        $log4netLoggerDebug.debug("--------------------------------------------------")

        # Note the version of PowerShell we are working with.
        $log4netLoggerDebug.debug("The PowerShell version is: $($PSVersionTable.PSVersion.ToString()). The value of psVersionAbove4 is $psVersionAbove4")

        <#
            - Prep. and sanity checks
        #>
        # Check for the temp download folder
        $tempDirPath = "$PSScriptRoot/../Artefacts/Temp"
        if (-not (Test-Path -Path $tempDirPath)) {
            try {
                New-Item -Path "$PSScriptRoot/../Artefacts" -Name "Temp" -ItemType Directory -Force -ErrorAction Stop | Out-Null
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

        if (-not $PSBoundParameters.ContainsKey('APIKey')) {
            <#
                - Tests on and retrieval of the HealOps config file.
            #>
            $HealOpsConfigPath = "$PSScriptRoot/../Artefacts/HealOpsConfig.json"
            if(-not (Test-Path -Path $HealOpsConfigPath)) {
                $message = "The selfupdate feature of HealOps is disabled. Run Install-HealOpsPackage again & use the Package Management parameters."
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
                        [PSCustomObject]$HealOpsConfig = $HealOpsConfigText | out-string | ConvertFrom-Json
                    }

                    # Mark semaphore signaling that we are a' okay! to run a self-update cycle.
                    $canRunInstall = $true
                } catch {
                    $log4netLoggerDebug.Debug("The HealOps config file could not be locked. It is already being used. An update cyclus might therefore be occurring.")

                    # Mark semaphore to signal that we should not run an update as another process is potentially doing that already.
                    $canRunInstall = $false
                }

                if (-not $canRunInstall) {
                    # Failed to lock the HealOps config as another process is using it. Still need to read the config for this session to run is *.Tests.ps1 and *.Repairs.ps1 files.
                    if($psVersionAbove4) {
                        [PSCustomObject]$HealOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
                    } else {
                        [PSCustomObject]$HealOpsConfig = Get-Content -Path $HealOpsConfigPath | out-string | ConvertFrom-Json
                    }

                }

                if ($null -eq $healOpsConfig) {
                    $message = "The HealOpsConfig contains no data. Run Install-HealOpsPackage again & use the Package Management parameters."
                    Write-Verbose -Message $message
                    $log4netLogger.error("$message")

                    # Exit
                    throw $message
                } elseif(-not ($healOpsConfig.reportingBackend.Length -gt 1)) {
                    $message = "The HealOps config file is invalid. Run Install-HealOpsPackage again & use the Package Management parameters."
                    Write-Verbose -Message $message
                    $log4netLogger.error("$message")

                    # Exit
                    throw $message
                }
            }

            <#
                - Package Management variables
            #>
            # Use the values from the HealOps config file (it has been controlled in the above code)
            $APIKey = $healOpsConfig.PackageManagementAPIKey
            $FeedName = $healOpsConfig.FeedName
            $PackageManagementURI = $healOpsConfig.PackageManagementURI
        }

        <#
            - Variables
        #>
        # The job user of HealOps ... its username
        New-Variable -Name HealOpsUsername -Value "HealOps" -Option Constant -Description "The username of the local administrator user, used by HealOps" `
        -Visibility Private -Scope Script

        # Semaphore. Used to ensure we only verify that a HealOps user exists and works on the local system.
        [Bool]$healOpsUserConfirmed = $false
    }
    Process {
        if ($canRunInstall) {
            :whenHealOpsUserNOTConfirmed foreach ($item in $Package) {
                # Control if the HealOps package is already installed on the system
                try {
                    # Get the module. The newest version of it, if several is installed
                    $module = Get-Module -ListAvailable -Name $item -ErrorAction Stop
                } catch {
                    $log4netLogger.error("Failed to get the module > $($item) on the system. It failed with > $_")
                    Write-Output "Cannot continue.....because of the below error."
                    throw "Controlling that the module > $item, is not installed already failed. It failed with > $_"
                }

                # Control that the HealOps package is not installed already
                if (-not $module) {
                    # Query the Package Management backend
                    $moduleVersionToInstall = Get-LatestModuleVersion -PackageManagementURI $PackageManagementURI -FeedName $FeedName -ModuleName $item -APIKey $APIKey

                    if ($null -ne $moduleVersionToInstall) {
                        $extractModulePath = Get-ModuleExtractionPath -ModuleName $item -Version $moduleVersionToInstall

                        # Install the HealOps package
                        try {
                            $installResult = Install-AvailableUpdate -ModuleName $item -ModuleExtractionPath $extractModulePath -PackageManagementURI $PackageManagementURI -FeedName $FeedName -Version $moduleVersionToInstall
                        } catch {
                            $log4netLogger.error("Install-AvailableUpdate failed with > $_")
                            Write-Output "Install-AvailableUpdate failed with > $_"
                            Write-Host "The HealOps package named > $item was not installed." -ForegroundColor Red
                        }

                        if ($installResult) {
                            $log4netLoggerDebug.debug("The HealOps package was installed successfully.")
                            Write-Host "================================================================================================" -ForegroundColor Cyan
                            Write-Host "....The HealOps package named $item was installed successfully...."                               -ForegroundColor Green
                            Write-Host "================================================================================================" -ForegroundColor Cyan
                            Write-Host ""
                            Write-Host "================================================================================================" -ForegroundColor Cyan
                            Write-Host "........configuring the package."                               -ForegroundColor DarkGreen
                            Write-Host "================================================================================================" -ForegroundColor Cyan
                            Write-Host ""

                            if (-not $healOpsUserConfirmed) {
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

                            if ($healOpsUserConfirmed) {
                                # Get the HealOps package we just installed
                                [System.Collections.Generic.List[PSModuleInfo]]$installedHealOpsPackage = Get-InstalledHealOpsPackage -Package $item

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
                                                    $jobCreationResult = New-HealOpsPackageJob -TestsBaseFileName $baseFileName -JobInterval $TestsFileJobInterval -JobType $JobType -Package $installedHealOpsPackage -Password $clearTextJobPassword -UserName $HealOpsUsername
                                                } catch {
                                                    $log4netLogger.error("Failed to create a job for the *.Tests.ps1 file named > $baseFileName. Failed with > $_")
                                                }
                                            }
                                        }
                                    } else {
                                        $log4netLogger.error("No HealOps config file was returned. No HealOps jobs where created.")
                                    }
                                } else {
                                    $log4netLogger.error("There seems to be no *.Tests.ps1 files in the HealOps package named > $item. No HealOps jobs where created.")
                                }

                                # Remove the contents of the download temp dir.
                                try {
                                    Get-ChildItem -Path $tempDirPath -Force -Recurse -ErrorAction Stop | Remove-Item -Force -Recurse -ErrorAction Stop
                                } catch {
                                    $log4netLogger.error("Cleaning up the download temp dir > $tempDirPath faild with > $_")
                                    Write-Output "Cleaning up the download temp dir > $tempDirPath faild with > $_"
                                }

                                <#
                                    - Info to installing person
                                #>
                                if ($jobCreationResult) {
                                    Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                    Write-Host "....The HealOps package named $item was setup successfully...."                               -ForegroundColor Green
                                    Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                    Write-Host ""
                                } else {
                                    Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                    Write-Host "....Failed to setup the HealOps package named $item...."                               -ForegroundColor Green
                                    Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                    Write-Host ""
                                }
                            } else {
                                # Exit the script. By mother of all beings...we really need a locally working HealOps user. So no reason to continue.
                                $log4netLogger.error("Failed to confirm a locally setup and properly configured HealOps user.")
                                Write-Output "Failed to confirm a locally setup and properly configured HealOps user. Cannot continue...exciting!"
                                Write-Output "Check the HealOps InstallHealOpsPackage log file for more info."

                                # Now exit - Exits to the labeled foreach item in package and code execution is then continued below the foreach.
                                break whenHealOpsUserNOTConfirmed
                            } # End of conditional control on that the requirements of a local HealOps could be confirmed.
                        } # End of conditional control on $installResult. Verifying that the HealOps package was installed correctly.
                    } else {
                        $log4netLoggerDebug.debug("The module > $item was not found on the Package Management backend > $PackageManagementURI.")
                        Write-Output "The module > $item was no found on the Package Management backend > $PackageManagementURI."
                    }
                } else {
                    # The HealOps package is already installed
                    $log4netLoggerDebug.debug("The HealOps package named $item is already installed on the local system.")
                    Write-Output "The HealOps package named $item is already installed on the local system."
                }
            } # End of foreach over specified packages to install.

            <#
                - Now configure the HealOps jobs that existed before executing Install-HealOpsPackage.
                    > We need to do this. If we don't, the jobs will not work as the password on the local HealOps user has been changed.
                    > Doesn't matter if the user existed already or not.
            #>
            if ($healOpsUserConfirmed) {
                Write-Host "==================================================================================================" -ForegroundColor DarkYellow
                Write-Host "- Now configuring HealOps packages that was on the system before running Install-HealOpsPackage."                               -ForegroundColor Green
                Write-Host "==================================================================================================" -ForegroundColor DarkYellow
                Write-Host ""

                # Get all packages not in $Packages
                [System.Collections.Generic.List[PSModuleInfo]]$HealOpsPackagesToUpdate = Get-InstalledHealOpsPackage -NotIn -Package $Package

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
                                            $log4netLogger.error("")
                                        }

                                        if ($null -ne $task) {
                                            # Set the password on the job
                                            try {
                                                Set-xScheduledTask -InputObject $task -Password $clearTextJobPassword
                                            } catch {
                                                Write-Output "$_ <-- you will have to set the password manually on the job named > $baseFileName"
                                                $log4netLogger.error("$_")
                                            }
                                        } else {
                                            Write-Output "No job exists for the *.Tests.ps1 file named > $baseFileName. Creating one!"
                                            $log4netLoggerDebug.Debug("No job exists for the *.Tests.ps1 file named > $baseFileName. Creating one!")

                                            # Get the jobInterval to use
                                            try {
                                                $currentErrorActionPreference = $ErrorActionPreference
                                                $ErrorActionPreference = "Stop"
                                                [int]$TestsFileJobInterval = $HealOpsPackageConfig.$baseFileName.jobInterval -as [int]
                                            } catch {
                                                $log4netLogger.error("Failed to determine the jobInterval value. Failed with > $_")
                                            } finally {
                                                $ErrorActionPreference = $currentErrorActionPreference
                                            }

                                            # Create a task for the *.Tests.ps1 file as no one currently exists
                                            try {
                                                $jobCreationResult = New-HealOpsPackageJob -TestsBaseFileName $baseFileName -JobInterval $TestsFileJobInterval -JobType $JobType -Package $packageToUpdate -Password $clearTextJobPassword -UserName $HealOpsUsername
                                            } catch {
                                                $log4netLogger.error("Failed to create a job for the *.Tests.ps1 file named > $baseFileName. Failed with > $_")
                                            }

                                            <#
                                                - Info to installing person
                                            #>
                                            if ($jobCreationResult) {
                                                Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                                Write-Host "....The job was created successfully...."                               -ForegroundColor Green
                                                Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                                Write-Host ""
                                            } else {
                                                Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                                Write-Host "....Failed to create the job....see the log for reasons."                               -ForegroundColor Green
                                                Write-Host "================================================================================================" -ForegroundColor DarkYellow
                                                Write-Host ""
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
                    $log4netLoggerDebug.Debug("There seems to have been no HealOps packages installed on the system prior to running Install-HealOpsPackage.")
                }
            } else {
                $log4netLoggerDebug.Debug("As the HealOps user was not changed, HealOps packages installed prior to running Install-HealOpsPackage was not touched.")
            }

            # Clean-up after messing with IT.........
            if ($canRunInstall) {
                try {
                    $HealOpsConfigFile.Close()
                    $HealOpsConfigReader.Close()
                    $log4netLoggerDebug.Debug("canRunInstall was $canRunInstall. Successfully closed the HealOps config lock & read resources.")
                } catch {
                    $log4netLogger.error("canRunInstall was $canRunInstall. Couldn't clean-up the HealOps config lock & read resources. Failed with > $_")
                }
            }
            Remove-Variable Password -Force
            #Remove-Variable credential -Force
            Remove-Variable clearTextPassword -Force
            [System.GC]::Collect()
        } else {
            $log4netLoggerDebug.Debug("canRunInstall has a value of $canRunInstall. Therefore Install-HealOpsPackage was halted before it got started. In order to avoid conflicting with an instance of HealOps
            already in the proces of executing a self-update cycle.")

            # Inform installer (the user executing Install-HealOpsPackage)
            Write-Output "HealOps is already in the process of running a self-update cycle. This conflicts with running Install-HealOpsPackage. You have the following options: `
                - Disable the HealOps jobs on the system > Then try again. `
                - Wait a sec. and execute Install-HealOpsPackage again. `
                - See the Install-HealOpsPackage log for more info....."
        } # End of conditional control on canRunInstall. If this is not $true we should not fully execute Install-HealOpsPackage as HealOps is running a self-update cycle that Install-HealOpsPackage could conflict with.
    }
    End {}
}