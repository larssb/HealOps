#Requires -RunAsAdministrator
<#PSScriptInfo

.VERSION 0.0.0.13

.GUID bbf74424-f58d-42d1-9d5a-aeba44ccd545

.AUTHOR Lars Bengtsson

.COMPANYNAME

.COPYRIGHT

.TAGS HealOps Installation Bootstrap

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.DESCRIPTION
    This is a script function that will install HealOps on "X" system.

    It will:
        - Write the HealOps config json file which HealOps uses as its configuration storage.
        - Configure a HealOps task that will invoke the HealOps package/packages to test, heal and report on "X" system.
        - Install HealOps and its required modules and components.
.INPUTS
    <none>
.OUTPUTS
    Outputs to the terminal/host as it goes.
.NOTES
    Install-HealOps uses the -Force parameter on the Instal-Modules cmdlet. In order to install side-by-side if an older version is already on the system and a newer is available
    on the Package Management system.
.EXAMPLE
    "PATH_TO_THIS_FILE"/Instal-HealOps.ps1 -reportingBackend 'OpenTSDB' -checkForUpdatesInterval_InDays 3 -PackageManagementURI https://proget.danskespil.dk -FeedName HealOps `
    -APIKey "API_KEY" -HealOpsPackages Citrix.HealOpsPackage -JobType WinScTask

    >> Executes Installs HealOps on the node where it is executed. Sets the reporting backend to use OpenTSDB. Updates will be checked for every third day. The PackageManagement system `
    is accessed via https://proget.danskespil.dk. The feed on the Package Management system is named HealOps. The HealOps packages that will be installed is named Citrix.HealOpsPackage `
    The type of the job that will invoke HealOps will be a Windows Scheduled Task.
.PARAMETER reportingBackend
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER checkForUpdatesInterval_InDays
    The interval in days between checking for updates. Specifying this implicitly also enables the check for updates feature.
.PARAMETER PackageManagementURI
    The URI of the Package Management backend, where modules used by HealOps are stored.
.PARAMETER FeedName
    The name of the feed on the Package Management backend, in which modules used by HealOps are stored.
.PARAMETER APIKey
    The API key to used when communicatnig with the Package Management backend.
.PARAMETER AnonymousNotAllowed
    Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.
.PARAMETER HealOpsPackages
    An Array containing the names of the HealOps packages to install on the system.
.PARAMETER JobType
    The type of job to use for invoking HealOps.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateSet('OpenTSDB')]
        [String]$reportingBackend,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="The interval in days between checking for updates. If you don't set this the self-update feature will not be activated.")]
        [ValidateNotNullOrEmpty()]
        [Int]$checkForUpdatesInterval_InDays,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The URI of the Package Management backend, where modules used by HealOps are stored.")]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the feed on the Package Management backend, in which modules used by HealOps are stored.")]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The API key to used when communicatnig with the Package Management backend.")]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.")]
        [Switch]$AnonymousNotAllowed,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="An Array containing the names of the HealOps packages to install on the system.")]
        [ValidateNotNullOrEmpty()]
        [Array]$HealOpsPackages,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of job to use for invoking HealOps.")]
        [ValidateSet('WinPSJob','WinScTask','LinCronJob')]
        [String]$JobType
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Define variables and other needed data
        #>
        # The name of the HealOps module.
        $HealOpsModuleName = "HealOps"

        # Prepare install-module parameter splatting
        $installModuleParms = @{}
        if ($AnonymousNotAllowed -eq $true) {
            $installModuleParms.Add("Credential",(Get-credential))
        }

        # Check for the temp download folder
        $tempDirPath = "$PSScriptRoot/Temp"
        if (-not (Test-Path -Path $tempDirPath)) {
            try {
                New-Item -Path $PSScriptRoot -Name "Temp" -ItemType Directory -Force -ErrorAction Stop
            } catch {
                throw "Faield to create the temp folder used for storing downloaded files. It failed with > $_. The script cannot continue."
            }
        }

        <#
            - Determine system agnostic values
        #>
        $script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
        if($script:IsInbox) {
            $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
        } else {
            $script:ProgramFilesPSPath = $PSHome
        }
        $script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath "Modules"

        <#
            - Helper modules
        #>
        function Get-LatestModuleVersion($PackageManagementURI,$APIKey,$FeedName,$ModuleName) {
            # Retrieve the ID for the feed
            try {
                $Request = Invoke-WebRequest -Uri "$PackageManagementURI/api/json/Feeds_GetFeed?API_Key=$APIKey&Feed_Name=$FeedName" -UseBasicParsing -ErrorAction Stop
            } catch {
                throw "Requesting the ID of the feed $FeedName on package management backend $PackageManagementURI failed with > $_"
            }
            $Feed = $Request.Content | ConvertFrom-Json

            # Retrieve the package and version requested
            $URI = "$PackageManagementURI/api/json/NuGetPackages_GetLatest?API_Key=$APIKey&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$ModuleName"
            try {
                $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Stop
            } catch {
                throw "Retrieving the package and version on the package management backend $PackageManagementURI failed with > $_"
            }
            $PackageVersion = $Request.Content | ConvertFrom-Json

            # Return
            Write-Output($PackageVersion.Version_Text)
        }

        function Install-AvailableUpdate($PackageManagementURI,$ModuleName,$Version,$FeedName,$ProgramFilesModulesPath) {
            # Download the module
            try {
                Invoke-WebRequest -Uri "$PackageManagementURI/nuget/$FeedName/package/$ModuleName/$Version" -UseBasicParsing -OutFile $PSScriptRoot/Temp/$ModuleName.zip -ErrorAction Stop
            } catch {
                throw "Downloading the module named > $ModuleName from the feed named > $FeedName on the package management backend > $PackageManagementURI `
                failed with > $_"
            }

            if (Test-Path -Path $PSScriptRoot/Temp/$ModuleName.zip) {
                # Extract the package
                try {
                    Expand-Archive $PSScriptRoot/Temp/$ModuleName.zip -DestinationPath $ProgramFilesModulesPath/$ModuleName/$Version -Force -ErrorAction Stop
                } catch {
                   throw "Failed to extract the nuget package. The extraction failed with > $_"
                }
            } else {
                throw "The nuget package could not be found. Was it downloaded successfully? The script cannot continue. Did the download fail?"
            }
        }
    }
    Process {
        <#
            - Install HealOps and its required modules.
        #>
        # If HealOps is already loaded in the current runspace. Remove the module
        Remove-Module -Name $HealOpsModuleName -Force -ErrorAction SilentlyContinue # Ok to continue silently > if it failed the module was not there to remove and that is what we want.

        # Get the latest version of the HealOps module.
        try {
           $latestModuleVersion = Get-LatestModuleVersion -PackageManagementURI $PackageManagementURI -APIKey $APIKey -FeedName $FeedName -ModuleName $HealOpsModuleName
        } catch {
            throw "Could not get the latest version of the module $HealOpsModuleName. It failed with > $_"
        }

        # Control the local system to confirm if the module is already installed
        $moduleAlreadyThere = (Get-Module -ListAvailable -Name $HealOpsModuleName)
        if ($null -ne $moduleAlreadyThere) {
            $newestModuleAlreadyThere = ($moduleAlreadyThere | Sort-Object -Property Version -Descending)[0]
            $reasonToUpdate = $latestModuleVersion -gt $newestModuleAlreadyThere.Version
            Write-Verbose -Message "We are here and the result of the compare is > $reasonToUpdate. The versions are: latest on PackManURI > $latestModuleVersion and locally > $($newestModuleAlreadyThere.Version)"
        } else {
            $reasonToUpdate = $true
        }

        if ($reasonToUpdate -eq $true) {
            # Install HealOps
            if ($null -ne $latestModuleVersion -or $latestModuleVersion.length -ge 1) {
                Write-Progress -Activity "Installing HealOps" -CurrentOperation "Installing the HealOps module." -Id 1
                Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $HealOpsModuleName -Version $latestModuleVersion -FeedName $FeedName -ProgramFilesModulesPath $ProgramFilesModulesPath
            }
        } else {
            Write-Verbose -Message "There was no reason to upgrade as the locally installed module > $HealOpsModuleName is either newer or at the same version as the one on the Package Management system."
        }

        # Installation of HealOps required modules
        if ( (Test-Path -Path $ProgramFilesModulesPath/$HealOpsModuleName/$latestModuleVersion) -or (Test-Path -Path $ProgramFilesModulesPath/$HealOpsModuleName/$newestModuleAlreadyThere.Version) ) {
            # Get the required modules from the newest available HealOps module
            $requiredModules = (Get-Module -ListAvailable -Name $HealOpsModuleName | Sort-Object -Property Version -Descending)[0].RequiredModules

            # Install the modules
            foreach ($requiredModule in $requiredModules) {
                # Remove the requiredModule from the current runspace if it is loaded.
                Remove-Module -Name $requiredModule -Force -ErrorAction SilentlyContinue # Ok to continue silently > if it failed the module was not there to remove and that is what we want.

                # Get the latest version of the required module.
                try {
                    $latestRequiredModuleVersion = Get-LatestModuleVersion -PackageManagementURI $PackageManagementURI -APIKey $APIKey -FeedName $FeedName -ModuleName $requiredModule.Name
                } catch {
                    throw "Could not get the latest version of the module $($requiredModule.Name). It failed with > $_"
                }

                # Control the local system to confirm if the module is already installed
                $requiredModuleAlreadyThere = Get-Module -ListAvailable -Name $requiredModule.Name
                if ($null -ne $requiredModuleAlreadyThere) {
                    $newestRequiredModuleAlreadyThere = ($requiredModuleAlreadyThere | Sort-Object -Property Version -Descending)[0]
                    $reasonToUpdate = $latestRequiredModuleVersion -gt $newestRequiredModuleAlreadyThere.Version
                    Write-Verbose -Message "We are here and the result of the compare is > $reasonToUpdate. The versions are: latest on PackManURI > $latestRequiredModuleVersion and locally > $($newestRequiredModuleAlreadyThere.Version)"
                } else {
                    $reasonToUpdate = $true
                    Write-Verbose -Message "The required module was not found. Let's install the required module > $requiredModule"
                }

                if ($reasonToUpdate -eq $true) {
                    try {
                        Write-Progress -Activity "Installing HealOps" -CurrentOperation "Installing the HealOps dependency module $requiredModule." -Id 2
                        Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $requiredModule.Name -Version $latestRequiredModuleVersion -FeedName $FeedName -ProgramFilesModulesPath $ProgramFilesModulesPath
                    } catch {
                        throw "Failed to install the HealOps required module $requiredModule. It failed with > $_"
                    }
                } else {
                    Write-Verbose -Message "There was no reason to upgrade as the locally instaled module > $($requiredModule.Name) is either newer or at the same version as the one on the Package Management system."
                }
            }
        } else {
            throw "HealOps seems not to be successfully installed. The path $ProgramFilesModulesPath/$HealOpsModuleName/$latestModuleVersion or $ProgramFilesModulesPath/$HealOpsModuleName/$($newestModuleAlreadyThere.Version) could not be verified."
        }

        # Check that HealOps is available
        $HealOpsModule = (Get-Module -ListAvailable -Name $HealOpsModuleName | Sort-Object -Property Version -Descending)[0]
        $HealOpsModuleBase = $HealOpsModule.ModuleBase
        if ($HealOpsModule.Name -eq $HealOpsModuleName) {
            <#
                - The HealOps config json file.
            #>
            Write-Progress -Activity "Installing HealOps" -CurrentOperation "Defining the HealOps config json file." -Id 3
            $HealOpsConfig = @{}
            $HealOpsConfig.reportingBackend = $reportingBackend
            $HealOpsConfig.PackageManagementURI = $PackageManagementURI
            $HealOpsConfig.FeedName = $FeedName
            $HealOpsConfig.PackageManagementAPIKey = $APIKey
            if($null -ne $checkForUpdatesInterval_InDays) {
                $HealOpsConfig.checkForUpdates = "True"
                $HealOpsConfig.checkForUpdatesInterval_InDays = $checkForUpdatesInterval_InDays
                $HealOpsConfig.checkForUpdatesNext = "" # Real value provided when HealOps is running and have done its first update cycle pass.
            } else {
                $HealOpsConfig.checkForUpdates = "False"
            }

            # Convert to JSON
            Write-Progress -Activity "Installing HealOps" -CurrentOperation "Writing the HealOps config json file." -Id 4
            $HealOpsConfig_InJSON = ConvertTo-Json -InputObject $HealOpsConfig -Depth 3
            Write-Verbose -Message "HealOpsConfig JSON to write to the HealOpsConfig json file > $HealOpsConfig_InJSON"

            # Write the HealOps config json file
            try {
                Set-Content -Path "$HealOpsModuleBase/Artefacts/HealOpsConfig.json" -Value $HealOpsConfig_InJSON -Force -ErrorAction Stop
            } catch {
                throw "Writing the HealOps config json file failed with: $_"
            }
            <#
                - Create privileged user for the HealOps task
            #>
            # Password for the local user
            $numbers = 1..100
            $randomNumbers = Get-Random -InputObject $numbers -Count 9
            $chars = [char[]](0..255) -clike '[A-z]'
            $randomChars = Get-Random -InputObject $chars -Count 9
            $charsAndNumbers = $randomNumbers
            $charsAndNumbers += $randomChars
            $charsAndNumbersShuffled = $charsAndNumbers | Sort-Object {Get-Random}
            $password = ConvertTo-SecureString -String ($charsAndNumbersShuffled -join "") -AsPlainText -Force
            $clearTextPassword = ($charsAndNumbersShuffled -join "")

            # Create the user
            $HealOpsUsername = "HealOps"
            $HealOpsUser = Get-LocalUser -Name $HealOpsUsername -ErrorAction SilentlyContinue
            if ($null -ne $HealOpsUser) {
                try {
                    $HealOpsUser | Set-LocalUser -Password $password
                } catch {
                    throw "Could not set the generated password on the already existing HealOps user "
                }

                # Check if it is a member of the Administrators group
                $matchOrNot = (Get-LocalGroupMember -SID S-1-5-32-544).Name -match $HealOpsUsername -as [Bool]
                if ($matchOrNot -eq $false) {
                    # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
                    try {
                        Add-LocalGroupMember -SID S-1-5-32-544 -Member $HealOpsUser
                    } catch {
                        throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
                    }
                }
            } else {
                # Create the HealOps user.
                try {
                    $HealOpsUser = New-LocalUser -Name $HealOpsUsername -AccountNeverExpires -Description "Used to execute HealOps tests & repairs files." -Password $password -PasswordNeverExpires -UserMayNotChangePassword
                } catch {
                    throw "Failed to create a batch user for HealOps. The error was > $_"
                }

                # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
                try {
                    Add-LocalGroupMember -SID S-1-5-32-544 -Member $HealOpsUser
                } catch {
                    throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
                }
            }

            # Create credentials object used when registering the scheduled job.
            $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $HealOpsUsername, $password

            # Install HealOps packages
            foreach ($HealOpsPackage in $HealOpsPackages) {
                # Get the latest version of the HealOps package.
                try {
                    $latestModuleVersion = Get-LatestModuleVersion -PackageManagementURI $PackageManagementURI -APIKey $APIKey -FeedName $FeedName -ModuleName $HealOpsPackage
                } catch {
                    Write-Output "Could not get the latest version of the HealOps Package $HealOpsPackage. It failed with > $_. This package will not be installed."
                }

                if ($null -ne $latestModuleVersion -or $latestModuleVersion.length -ge 1) {
                    try {
                        Write-Progress -Activity "Installing HealOps" -CurrentOperation "Installing the HealOps package $HealOpsPackage." -Id 4
                        Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $HealOpsPackage -Version $latestModuleVersion -FeedName $FeedName -ProgramFilesModulesPath $ProgramFilesModulesPath
                    } catch {
                        Write-Output "Failed to install the HealOps package > $HealOpsPackage. It failed with > $_"
                        $healOpsPackageInstallationResult = "failed"
                    }

                    if ($null -eq $healOpsPackageInstallationResult) {
                        <#
                            - Tasks for running HealOps package tests
                                -- 1 task per *.Tests.ps1 file in the TestsAndRepairs folder given.
                        #>
                        $HealOpsPackageModuleBase = Split-Path -Path (Get-Module -ListAvailable -Name $HealOpsPackage).ModuleBase | Select-Object -Unique
                        $HealOpsPackageModuleRootBase = "$HealOpsPackageModuleBase/$latestModuleVersion"

                        # Get the *.Tests.ps1 files in the provided directory
                        $TestsFiles = Get-ChildItem -Path $HealOpsPackageModuleRootBase/TestsAndRepairs -Recurse -Force -Include "*.Tests.ps1"
                        foreach ($testFile in $TestsFiles) {
                            [Array]$HealOpsPackageConfig = Get-Content -Path $HealOpsPackageModuleRootBase/Config/*.json -Encoding UTF8 | ConvertFrom-Json
                            $TestsFileName = Split-Path -Path $testFile -Leaf
                            $fileExt = [System.IO.Path]::GetExtension($TestsFileName)
                            $fileNoExt = $TestsFileName -replace $fileExt,""
                            $TestsFileJobInterval = $HealOpsPackageConfig.$fileNoExt.jobInterval
                            Write-Verbose -Message "The job repetition interval will be > $TestsFileJobInterval"

                            ################
                            # JOB CREATION #
                            ################
                            $HealOpsPackageConfigPath = Get-ChildItem -Path $HealOpsPackageModuleRootBase/Config -Include "*.json" -Force -File -Recurse
                            [String]$ScriptBlockString = "Invoke-HealOps -TestsFile '$testFile' -HealOpsPackageConfigPath '$($HealOpsPackageConfigPath.FullName)'"
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
                                        At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom)).ToString();
                                        RepetitionInterval = (New-TimeSpan -Minutes $TestsFileJobInterval);
                                        RepeatIndefinitely = $true;
                                        Once = $true;
                                    }
                                    try {
                                        New-ScheduledJob -TaskName $fileNoExt -TaskOptions $Options -TaskTriggerOptions $Trigger -TaskPayload "ScriptBlock" -ScriptBlock $ScriptBlockString -credential $credential -verbose
                                    } catch {
                                        throw $_
                                    }
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
                                            At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom)).ToString()
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
                                    } else {
                                        # Use the classic schtasks cmd.
                                        <#
                                            The settings explained:
                                            - ToRun: The value to hand to the /TR parameter of the schtasks cmd. Everything after powershell.exe will be taken as parameters.
                                        #>
                                        $executeFileFullPath = "$HealOpsPackageModuleRootBase/TestsAndRepairs/execute.$TestsFileName"
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
                                    }
                                }
                                # Cron job - LINUX
                                "LinCronJob" {

                                }
                                Default {}
                            }
                        }
                    } else {
                        try {
                            # Clean-up
                            Remove-Variable -name healOpsPackageInstallationResult -Force -ErrorAction Stop
                        } catch {
                            Write-Output "Faild to remove the variable named healOpsPackageInstallationResult. Might give issues."
                        }
                    }
                }
            }

            <#
                - Clean-up
            #>
            # Remove the password variable from memory
            Remove-Variable Password -Force
            Remove-Variable credential -Force
            Remove-Variable clearTextPassword -Force
            [System.GC]::Collect()

            # Remove the contents of the download temp dir.
            if($reasonToUpdate -eq $true) {
                try {
                    Remove-Item -Path $tempDirPath -Force -Recurse -Include *.zip -ErrorAction Stop
                } catch {
                    Write-Output "Cleaning up the download temp dir > $tempDirPath faild with > $_"
                }
            }

            <#
                - Info to installing person
            #>
            write-host "========================================================================================" -ForegroundColor DarkYellow
            write-host "....HealOps was installed...." -ForegroundColor Green
            write-host " - DO REMEMBER TO SET environment specific values in the HealOps packages you specified." -ForegroundColor Red
            write-host " - They where > $HealOpsPackages" -ForegroundColor Green
            write-host " - And are installed in the following PowerShell module root > $ProgramFilesModulesPath." -ForegroundColor Green
            write-host "========================================================================================" -ForegroundColor DarkYellow
        } else {
            throw "The HealOps module does not seem to be installed. So we have to stop."
        }
    }
    End {}