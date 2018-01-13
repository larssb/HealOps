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
                # Check file integrity & get config data
                if($psVersionAbove4) {
                    [PSCustomObject]$healOpsConfig = Get-Content -Path $HealOpsConfigPath -Encoding UTF8 | ConvertFrom-Json
                } else {
                    [PSCustomObject]$healOpsConfig = Get-Content -Path $HealOpsConfigPath | out-string | ConvertFrom-Json
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
                                            [int]$TestsFileJobInterval = $HealOpsPackageConfig.$fileNoExt.jobInterval -as [int]
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
            # Inform the user about what is going on!

            # Get all packages -not in Packages to Install-HealOpsPackage()
                ## use [System.Collections.Generic.List[PSModuleInfo]]$HealOpsPackagesToUpdate = Get-InstalledHealOpsPackage -Package $Package -NotIn
            # foreach package > get all tests files
                ## use > $TestsFiles = Get-HealOpsPackageTestsFile -Package "My.HealOpsPackage" <<- when foreach'ing
            # foreach testsfile > find/match the job (Scheduled Task) relative to the *.Tests.ps1 file
                ## Create functions that supports the ScheduledTasks PS module.
            #  Set the updated $Password on each found job

            ## Could create a job for a *.Tests.ps1 in a package that isn't created a job for. But think about it!!

            <#
                - not foR HERE buT
                When updating HealOps packages.

                # If a job for just 1 new *.Tests.ps1 file in an updated HealOps package. A HealOps user password set...therefore.
                # Set a password on jobs already created for the updated package
                # Foreach HealOps package not updated ...set the new password on the job

                ### !!! DO SOMETHING ABOUT THE BELOW
                because of same time issues and race for setting password on the HealOps user and jobs for each *.Tests.ps1
                file we could get serious issues.
                Therefore > find a solution. E.g.
                    > Lock the HealOps config file > If locked == exit Healops...the next time the job will be executed
                    it works.
                        >> How do you lock a file in PowerShell?
                    > Write to the HealOps config file early early > so that other jobs on 'x' self-update property can
                    control if they should back of from self-updating. As another job is already doing that.
            #>
        }

        # Clean-up after messing with IT.........
        Remove-Variable Password -Force
        #Remove-Variable credential -Force
        Remove-Variable clearTextPassword -Force
        [System.GC]::Collect()
    }
    End {}
}