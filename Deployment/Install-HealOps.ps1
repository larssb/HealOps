<#PSScriptInfo
.VERSION 0.0.0.21
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
    <none>
.EXAMPLE
    "PATH_TO_THIS_FILE"/Instal-HealOps.ps1 -reportingBackend 'OpenTSDB' -checkForUpdatesInterval_Hours 3 -PackageManagementURI https://My.PackageManagementServer.com -FeedName HealOps `
    -APIKey "API_KEY" -HealOpsPackages Citrix.HealOpsPackage -JobType WinScTask

    >> Executes Installs HealOps on the node where it is executed. Sets the reporting backend to use OpenTSDB. Updates will be checked for every third day. The PackageManagement system `
    is accessed via https://My.PackageManagementServer.com. The feed on the Package Management system is named HealOps. The HealOps packages that will be installed is named Citrix.HealOpsPackage `
    The type of the job that will invoke HealOps will be a Windows Scheduled Task.
.PARAMETER AnonymousNotAllowed
    Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.
.PARAMETER APIKey
    The API key to used when communicatnig with the Package Management backend.
.PARAMETER checkForUpdatesInterval_Hours
    The interval in hours between checking for updates. Specifying this implicitly also enables the check for updates feature.
.PARAMETER FeedName
    The name of the feed on the Package Management backend, in which modules used by HealOps are stored.
.PARAMETER HealOpsPackages
    An Array containing the names of the HealOps packages to install on the system.
.PARAMETER JobType
    The type of job to use when invoking HealOps.
.PARAMETER PackageManagementURI
    The URI of the Package Management backend, where modules used by HealOps are stored.
.PARAMETER reportingBackend
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER UpdateMode
    The execute mode that the self-update should use.
        > All = Everything will be updated. HealOps itself, its required modules and the HealOps packages on the system.
        > HealOpsPackages = Only HealOps packages will be updated.
        > HealOps = Only HealOps itself and its requird modules will be updated.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Void])]
    param(
        [Parameter()]
        [Switch]$AnonymousNotAllowed,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Int]$checkForUpdatesInterval_Hours,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Array]$HealOpsPackages,
        [Parameter(Mandatory)]
        [ValidateSet('WinPSJob','WinScTask','LinCronJob')]
        [String]$JobType,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI,
        [Parameter(Mandatory)]
        [ValidateSet('OpenTSDB')]
        [String]$reportingBackend,
        [Parameter()]
        [ValidateSet("All","HealOpsPackages","HealOps")]
        [String]$UpdateMode
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
            - Determine system specific values
        #>
        $script:IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
        if($script:IsInbox) {
            $script:ProgramFilesPSPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
        } else {
            $script:ProgramFilesPSPath = $PSHome
        }
        $script:ProgramFilesModulesPath = Microsoft.PowerShell.Management\Join-Path -Path $script:ProgramFilesPSPath -ChildPath "Modules"

        # Control the systems system level PSModule path.
        $currentPSModulePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")

        if(-not ($currentPSModulePath.contains($ProgramFilesModulesPath) ) ) {
            # Define the new PSModulePath to add to the system level PSModule path
            $newPSModulePath = $currentPSModulePath+';'+$ProgramFilesModulesPath

            # Add the defined PSModulePath to the system level PSModulepath for future PowerShell sessions
            #### TRY / CATCH HERE
            [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath, "Machine")

            # Add the specified PSModulePath to the current session path for this to work right now
            $env:PSModulePath += ";$newPSModulePath"
        }

        # PowerShell below 5 is not module versioning compatible. Reflect this.
        if($PSVersionTable.PSVersion.ToString() -gt 4) {
            [Boolean]$psVersionAbove4 = $true
        } else {
            [Boolean]$psVersionAbove4 = $false
        }

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
                New-Item -Path $PSScriptRoot -Name "Temp" -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                throw "Failed to create the temp folder used for storing downloaded files. It failed with > $_. The script cannot continue."
            }
        }

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

        function Get-ModuleExtractionPath ($modulename,$psVersionAbove4,$Version) {
            # Define the path to extract to
            if($psVersionAbove4) {
                $extractModulePath = "$ProgramFilesModulesPath/$modulename/$Version"
            } else {
                # No version value in the path def.
                $extractModulePath = "$ProgramFilesModulesPath/$modulename"

                # Remove the module folder if it is already present - PS v4 and below
                if(-not $psVersionAbove4) {
                    if(Test-Path -Path $extractModulePath) {
                        try {
                            Get-ChildItem -Path $extractModulePath -Force -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop # Using Get-childitem and piping to be compatible with PSv3
                        } catch {
                            Write-Output "Cannot continue...."
                            throw "Failed to remove the already existing module folder, for the module named $ModuleName (prep. for installing the module on a system with a PowerShell version `
                            that do not support module versioning). It failed with > $_"
                        }
                    }
                }
            }

            # Return
            [String]$extractModulePath
        }

        function Install-AvailableUpdate($PackageManagementURI,$ModuleName,$Version,$FeedName,$extractModulePath) {
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
                    if(Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue) {
                        Expand-Archive $PSScriptRoot/Temp/$ModuleName.zip -DestinationPath $extractModulePath -Force -ErrorAction Stop
                    } else {
                        # Add the .NET compression class to the current session
                        Add-Type -Assembly System.IO.Compression.FileSystem

                        # Extract the zip file
                        [System.IO.Compression.ZipFile]::ExtractToDirectory("$PSScriptRoot/Temp/$ModuleName.zip", "$extractModulePath")
                    }
                } catch {
                   throw "Failed to extract the nuget package. The extraction failed with > $_"
                }
            } else {
                throw "The nuget package could not be found. Was it downloaded successfully? The script cannot continue."
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

        # Control the local system to confirm if the latest version of the module is already installed.
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
                $extractModulePath = Get-ModuleExtractionPath -modulename $HealOpsModuleName -psVersionAbove4 $psVersionAbove4 -Version $latestModuleVersion
                Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $HealOpsModuleName -Version $latestModuleVersion -FeedName $FeedName -extractModulePath $extractModulePath
            }
        } else {
            Write-Verbose -Message "There was no reason to upgrade as the locally installed module > $HealOpsModuleName is either newer or at the same version as the one on the Package Management system."
        }

        # Get the required modules from the newest available HealOps module
        $installedHealOpsModules = Get-Module -ListAvailable -Name $HealOpsModuleName -ErrorAction SilentlyContinue
        if($null -ne $installedHealOpsModules) {
            $requiredModules = ($installedHealOpsModules | Sort-Object -Property Version -Descending)[0].RequiredModules
        } else {
            throw "HealOps seems not to be installed. The Install-HealOps script cannot continue."
        }

        # Install the modules that HealOps requires.
        if ($null -ne $requiredModules) {
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
                        $extractModulePath = Get-ModuleExtractionPath -modulename $requiredModule.Name -psVersionAbove4 $psVersionAbove4 -Version $latestRequiredModuleVersion
                        Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $requiredModule.Name -Version $latestRequiredModuleVersion -FeedName $FeedName -extractModulePath $extractModulePath
                    } catch {
                        throw "Failed to install the HealOps required module $requiredModule. It failed with > $_"
                    }
                } else {
                    Write-Verbose -Message "There was no reason to upgrade as the locally instaled module > $($requiredModule.Name) is either newer or at the same version as the one on the Package Management system."
                }
            }
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
            if($PSBoundParameters.ContainsKey('checkForUpdatesInterval_Hours') ) {
                $HealOpsConfig.checkForUpdates = "True"
                $HealOpsConfig.checkForUpdatesInterval_Hours = $checkForUpdatesInterval_Hours
                $HealOpsConfig.checkForUpdatesNext = "" # Real value provided when HealOps is running and have done its first update cycle pass.
                $HealOpsConfig.PackageManagementURI = $PackageManagementURI
                $HealOpsConfig.FeedName = $FeedName
                $HealOpsConfig.PackageManagementAPIKey = $APIKey
                $HealOpsConfig.UpdateMode = $UpdateMode
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
            # General user creation/control variables
            $HealOpsUsername = "HealOps"

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

            # Control if the user already exists
            $HealOpsUserDescription = "Used to execute HealOps tests & repairs files."
            if($psVersionAbove4) {
                $HealOpsUser = Get-LocalUser -Name $HealOpsUsername -ErrorAction SilentlyContinue
            } else {
                ####################
                # ADSI METHODOLOGY #
                ####################
                $ADSI = [ADSI]("WinNT://localhost")
                $currentErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = "SilentlyContinue"
                $HealOpsUser = $ADSI.PSBase.Children.Find("$HealOpsUsername")
                $ErrorActionPreference = $currentErrorActionPreference
            }

            if($psVersionAbove4) {
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
                        $HealOpsUser = New-LocalUser -Name $HealOpsUsername -AccountNeverExpires -Description $HealOpsUserDescription -Password $password -PasswordNeverExpires -UserMayNotChangePassword
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
            } else {
                ####################
                # ADSI METHODOLOGY #
                ####################
                if ($null -ne $HealOpsUser) {
                    # The HealOps user already exist. Set the password.
                    try {
                        $HealOpsUser.SetPassword($clearTextPassword)
                        $HealOpsUser.SetInfo()
                    } catch {
                        throw "Could not set the generated password on the already existing HealOps user "
                    }

                    # Control if the user is already a memberOf the local Administrators group
                    $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                    [Boolean]$alreadyMember = ($AdministratorsGroup.Invoke("Members") | ForEach-Object { $_[0].GetType().InvokeMember("Name", 'GetProperty', $null,$_, $null) }).contains("$HealOpsUsername")
                    if(-not ($alreadyMember)) {
                        # Add the user to the 'Administrators' group.
                        try {
                            $AdministratorsGroup.invoke("Add", "WinNT://$env:COMPUTERNAME/$HealOpsUsername,user")
                        } catch {
                            throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
                        }
                    }
                } else {
                    # Create the HealOps user.
                    try {
                        $HealOpsUser = $ADSI.Create('User', "$HealOpsUsername");
                        $HealOpsUser.SetPassword($clearTextPassword)
                        $HealOpsUser.SetInfo()
                        $HealOpsUser.Description = "$HealOpsUserDescription"
                        $HealOpsUser.SetInfo()
                        $HealOpsUser.UserFlags = 66145 # Sets: 'User cannot change password' and 'Password never expires'
                        $HealOpsUser.SetInfo()
                    } catch {
                        throw "Failed to create a batch user for HealOps. The error was > $_"
                    }

                    # Add the user to the 'Administrators' group.
                    $AdministratorsGroup = $ADSI.PSBase.Children.Find("Administrators")
                    try {
                        $AdministratorsGroup.invoke("Add", "WinNT://$env:COMPUTERNAME/$HealOpsUsername,user")
                    } catch {
                        throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
                    }

                    # Clean-up
                    # To release resources used via ADSI.
                    $currentErrorActionPreference = $ErrorActionPreference
                    $ErrorActionPreference = "SilentlyContinue"
                    $HealOpsUser.Close()
                    $AdministratorsGroup.Close()
                    $ErrorActionPreference = $currentErrorActionPreference
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
                        $extractModulePath = Get-ModuleExtractionPath -modulename $HealOpsPackage -psVersionAbove4 $psVersionAbove4 -Version $latestModuleVersion
                        Install-AvailableUpdate -PackageManagementURI $PackageManagementURI -ModuleName $HealOpsPackage -Version $latestModuleVersion -FeedName $FeedName -extractModulePath $extractModulePath
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
                        if($psVersionAbove4) {
                            $HealOpsPackageModuleRootBase = "$HealOpsPackageModuleBase/$latestModuleVersion"
                        } else {
                            $HealOpsPackageModuleRootBase = "$HealOpsPackageModuleBase/$HealOpsPackage"
                        }

                        # Get the *.Tests.ps1 files in the provided directory
                        $TestsFiles = Get-ChildItem -Path $HealOpsPackageModuleRootBase/TestsAndRepairs -Recurse -Force -Include "*.Tests.ps1"
                        foreach ($testFile in $TestsFiles) {
                            if($psVersionAbove4) {
                                [Array]$HealOpsPackageConfig = Get-Content -Path $HealOpsPackageModuleRootBase/Config/*.json -Encoding UTF8 | ConvertFrom-Json
                            } else {
                                [Array]$HealOpsPackageConfig = Get-Content -Path $HealOpsPackageModuleRootBase/Config/*.json | out-string | ConvertFrom-Json
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
                                    } else {
                                        # Use the classic schtasks cmd.
                                        <#
                                            The settings explained:
                                            - ToRun: The value to hand to the /TR parameter of the schtasks cmd. Everything after powershell.exe will be taken as parameters.
                                        #>
                                        $executeFileFullPath = "$HealOpsPackageModuleRootBase/TestsAndRepairs/execute.$TestsFileName"
                                        $Options = @{
                                            Username = $HealOpsUsername
                                            Password = $clearTextPassword
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
                                Default {
                                    Write-Output "None of the job types matched. The selected job type was > $JobType."
                                }
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
                    Get-ChildItem -Path $tempDirPath -Include *.zip -Force -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop # Using Get-childitem and piping to be compatible with PSv3
                } catch {
                    Write-Output "Cleaning up the download temp dir > $tempDirPath faild with > $_"
                }
            }

            <#
                - Info to installing person
            #>
            write-host "=============================" -ForegroundColor DarkYellow
            write-host "....HealOps was installed...." -ForegroundColor Green
            write-host "=============================" -ForegroundColor DarkYellow
        } else {
            throw "The HealOps module does not seem to be installed. So we have to stop."
        }
    }
    End {}