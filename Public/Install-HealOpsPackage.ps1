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
            - Other static variables
        #>
        New-Variable -Name HealOpsUsername -Value "HealOps" -Option Constant -Description "The username of the local administrator user, used by HealOps" `
        -Visibility Private -Scope Script
    }
    Process {
        foreach ($item in $Package) {
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
                        Write-Host "........configuring the $item."                               -ForegroundColor DarkGreen
                        Write-Host "================================================================================================" -ForegroundColor Cyan
                        Write-Host ""

                        # Setup jobs on the system. Foreach Test file in the HealOps package
                        $HealOpsPackageModuleBase = (Get-Module -ListAvailable -Name $item).ModuleBase
                        $log4netLoggerDebug.debug("HealOpsPackageModuleBase is > $HealOpsPackageModuleBase")

                        # Get the *.Tests.ps1 files in the provided directory
                        $TestsFiles = Get-ChildItem -Path $HealOpsPackageModuleBase/TestsAndRepairs -Recurse -Force -Include "*.Tests.ps1"

                        foreach ($testFile in $TestsFiles) {
                            if($psVersionAbove4) {
                                [Array]$HealOpsPackageConfig = Get-Content -Path $HealOpsPackageModuleBase/Config/*.json -Encoding UTF8 | ConvertFrom-Json
                            } else {
                                [Array]$HealOpsPackageConfig = Get-Content -Path $HealOpsPackageModuleBase/Config/*.json | out-string | ConvertFrom-Json
                            }

                            $TestsFileName = Split-Path -Path $testFile -Leaf
                            $fileExt = [System.IO.Path]::GetExtension($TestsFileName)
                            $fileNoExt = $TestsFileName -replace $fileExt,""
                            $TestsFileJobInterval = $HealOpsPackageConfig.$fileNoExt.jobInterval
                            Write-Verbose -Message "The job repetition interval will be > $TestsFileJobInterval"

                            ################
                            # JOB CREATION #
                            ################
                            [String]$ScriptBlockString = "Invoke-HealOps -TestsFileName '$fileNoExt' -HealOpsPackageName '$HealOpsPackage'"
                            Write-Progress -Activity "Installing HealOps" -CurrentOperation "Creating a task to execute HealOps. For the *.Tests.ps1 file > $testFile" -Status "With the following task repetition interval > $TestsFileJobInterval" -Id 5
                            switch ($JobType) {
                                # PowerShell Scheduled Job - WINDOWS
                                "WinPSJob" {
                                    <#
                                        The settings explained:
                                        - Be shown in the Windows Task Scheduler
                                        - Start if the computer is on batteries
                                        - Continue if the computer is on batteries
                                        - If the job is tried started manually and it is already executing, the new manually triggered job will queued
                                    #>
                                    $Options = @{
                                        StartIfOnBattery = $true;
                                        MultipleInstancePolicy = "Queue";
                                        RunElevated = $true;
                                        ContinueIfGoingOnBattery = $true;
                                    }

                                    <#
                                        The settings explained:
                                        - The trigger will schedule the job to run the first time at current date and time + 5min.
                                        - The task will be repeated with the incoming minute interval.
                                        - It will keep repeating forever.
                                    #>
                                    $kickOffJobDateTimeRandom = get-random -Minimum 2 -Maximum 6
                                    $Trigger = @{
                                        At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom))
                                        RepetitionInterval = (New-TimeSpan -Minutes $TestsFileJobInterval)
                                        RepeatIndefinitely = $true
                                        Once = $true
                                    }
                                    try {
                                        New-ScheduledJob -TaskName $fileNoExt -TaskOptions $Options -TaskTriggerOptions $Trigger -TaskPayload "ScriptBlock" -ScriptBlock $ScriptBlockString -credential $credential -verbose
                                    } catch {
                                        throw $_
                                    }

                                    # Semaphore
                                    $jobResult = $true
                                }
                                # Scheduled Task - WINDOWS
                                "WinScTask" {
                                    # Control if we can use the PowerShell module 'ScheduledTasks' to create the task.
                                    if ($null -ne (Get-Module -Name ScheduledTasks -ListAvailable) ) {
                                        # The options for the task to be registered.
                                        $Options = @{
                                            AllowStartIfOnBatteries = $true
                                            DontStopIfGoingOnBatteries = $true
                                            DontStopOnIdleEnd = $true
                                            MultipleInstances = "Queue"
                                            Password = $clearTextPassword
                                            PowerShellExeCommand = "$ScriptBlockString"
                                            RunLevel = "Highest"
                                            StartWhenAvailable = $true
                                            User = $HealOpsUsername
                                        }

                                        <#
                                            Task trigger. The settings explained:
                                                - RepetitionInterval: How often the task will be repeated.
                                                - RepetitionDuration: For how long the task will keep on repeating. As programmed it will keep on going for over 9000 days.
                                        #>
                                        $kickOffJobDateTimeRandom = get-random -Minimum 2 -Maximum 6
                                        $currentDate = ([DateTime]::Now)
                                        $taskRunDration = $currentDate.AddYears(25) - $currentDate
                                        $Trigger = @{
                                            At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom))
                                            RepetitionInterval = (New-TimeSpan -Minutes $TestsFileJobInterval)
                                            RepetitionDuration  = $taskRunDration
                                            Once = $true
                                        }

                                        # Create the task via the PowerShell ScheduledTasks module.
                                        try {
                                            Add-ScheduledTask -TaskName $fileNoExt -TaskOptions $Options -TaskTrigger $Trigger -Method "ScheduledTasks"
                                        } catch {
                                            throw "Creating the scheduled task via the ScheduledTasks PowerShell module failed with > $_"
                                        }

                                        # Semaphore
                                        $jobResult = $true
                                    } else {
                                        # Use the classic schtasks cmd.
                                        <#
                                            The settings explained:
                                            - ToRun: The value to hand to the /TR parameter of the schtasks cmd. Everything after powershell.exe will be taken as parameters.
                                        #>
                                        $executeFileFullPath = "$HealOpsPackageModuleBase/TestsAndRepairs/execute.$TestsFileName"
                                        $Options = @{
                                            Username = $HealOpsUsername
                                            Password = $password
                                            ToRun = "`"powershell.exe -NoLogo -NonInteractive -WindowStyle Hidden -File `"`"$executeFileFullPath`"`"`""
                                        }

                                        <#
                                            The settings explained:
                                            - RepetitionInterval: How often the task will be repeated.
                                        #>
                                        $Trigger = @{
                                            RepetitionInterval = $TestsFileJobInterval
                                        }

                                        # Create a CMD file for the scheduled task to execute. In order to avoid the limitation of the /TR parameter on the schtasks cmd. It cannot be longer than 261 chars.
                                        try {
                                            Set-Content -Path "$executeFileFullPath" -Value "$ScriptBlockString" -Force -NoNewline -ErrorAction Stop
                                        } catch {
                                            Write-Output "Failed to set content in the script for the scheduled task to execute. The task could there not be created for the Tests file > $TestsFileName > You'll have to create a task manually for this test."
                                        }

                                        if (Test-Path -Path "$executeFileFullPath") {
                                            try {
                                                # Create the task with the schtasks cmd.
                                                Add-ScheduledTask -TaskName $fileNoExt -TaskOptions $Options -TaskTrigger $Trigger -Method "schtasks"
                                            } catch {
                                                throw $_
                                            }
                                        }

                                        # Semaphore
                                        $jobResult = $true
                                    }
                                }
                                # Cron job - LINUX
                                "LinCronJob" {
                                        # Semaphore
                                        $jobResult = $true
                                }
                                Default {
                                    $log4netLogger.error("None of the job types matched. Not good <> bad.")
                                    Write-Output "None of the job types matched. The selected job type was > $JobType. Select a proper job type via the JobType parameter & try again."
                                }
                            }
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
                        if ($jobResult) {
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
                    } # End of conditional control on $installResult. Verifying that the HealOps package was installed correctly.
                } else {
                    $log4netLoggerDebug.debug("The module > $item was no found on the Package Management backend > $PackageManagementURI.")
                    Write-Output "The module > $item was no found on the Package Management backend > $PackageManagementURI."
                }
            } else {
                # The HealOps package is already installed
                $log4netLoggerDebug.debug("The HealOps package named $item is already installed on the local system.")
                Write-Output "The HealOps package named $item is already installed on the local system."
            }
        } # End of foreach over specified packages to install.
    }
    End{
    }
}