#Requires -RunAsAdministrator
<#PSScriptInfo

.VERSION 0.0.0.6

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
    "PATH_TO_THIS_FILE"/Instal-HealOps.ps1 -reportingBackend $reportingBackend -TaskName "MyHealOpsTask" -TaskRepetitionInterval 3 -
    Explanation of what the example does
.PARAMETER reportingBackend
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER checkForUpdatesInterval_InDays
    The interval in days between checking for updates. Specifying this implicitly also enables the check for updates feature.
.PARAMETER PackageManagementRepository
    The name of the repository, registered with Register-PSRepository, where modules used by HealOps are located.
.PARAMETER TaskName
    The name of the task.
.PARAMETER TaskRepetitionInterval
    The interval, in minutes, between repeating the task.
.PARAMETER TaskPayload
    The type of payload to invoke HealOps with.
.PARAMETER AnonymousNotAllowed
    Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateSet('OpenTSDB')]
        [String]$reportingBackend,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="The interval in days between checking for updates.")]
        [ValidateNotNullOrEmpty()]
        [Int]$checkForUpdatesInterval_InDays,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the repository, registered with Register-PSRepository, where modules used by HealOps are located.")]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementRepository,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the task.")]
        [ValidateNotNullOrEmpty()]
        [String]$TaskName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The interval, in minutes, between repeating the task.")]
        [ValidateNotNullOrEmpty()]
        [Int]$TaskRepetitionInterval,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of payload the task should execute when triggered.")]
        [ValidateSet('File','ScriptBlock')]
        [String]$TaskPayload,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Used to specify that the package management backend does not allow anonymous access. This will make the script prompt for credentials.")]
        [Switch]$AnonymousNotAllowed
    )

    DynamicParam {
        <#
            - General config for the FilePath or Scriptblock parameter relative to the TaskPayload value.
        #>
        # Configure parameter
        $attributes = new-object System.Management.Automation.ParameterAttribute
        $attributes.Mandatory = $true
        $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute
        [Type]$ParameterType = "String"

        # Define parameter collection
        $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($attributes)
        $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

        # Specific config
        if($TaskPayload -eq "File") {
            $attributes.HelpMessage = "The full path to the file that the task should execute when triggered."
            $ParameterName = "FilePath"
        } elseif($TaskPayload -eq "ScriptBlock") {
            $attributes.HelpMessage = "The scriptblock that the task should execute when triggered."
            $ParameterName = "ScriptBlock"
        }

        # Prepare to return & expose the parameter
        $Parameter = New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, $ParameterType, $AttributeCollection)
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add($ParameterName, $Parameter)
        return $paramDictionary
    }

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
    }
    Process {
        <#
            - Install HealOps and its required modules.
        #>
        # If HealOps is already loaded in the current runspace. Remove the module
        Remove-Module -Name $HealOpsModuleName -Force -ErrorAction SilentlyContinue # Ok to continue silently > if it failed the module was not there to remove and that is what we want.

        # Install HealOps
        Write-Progress -Activity "Installing HealOps" -CurrentOperation "Installing the HealOps module." -Id 1
        try {
            Install-Module -Name $HealOpsModuleName -Repository $PackageManagementRepository -Force @installModuleParms -ErrorAction Stop -ErrorVariable installModuleEV
        } catch {
            throw "Install-Module...failed with > $_"
        }

        # Installation of HealOps required modules
        if ($null -eq $installModuleEV) {
            # Get the required modules from the installed HealOps module
            $requiredModules = (Get-Module -All -Name $HealOpsModuleName).RequiredModules

            # Install the modules
            foreach ($requiredModule in $requiredModules) {
                # Remove the requiredModule from the current runspace if it is loaded.
                Remove-Module -Name $requiredModule -Force -ErrorAction SilentlyContinue # Ok to continue silently > if it failed the module was not there to remove and that is what we want.

                try {
                    Write-Progress -Activity "Installing HealOps" -CurrentOperation "Installing the HealOps dependency module $requiredModule." -Id 2
                    Install-Module -Name $requiredModule -Repository $PackageManagementRepository -Force @installModuleParms -ErrorAction Stop
                } catch {
                    throw "Failed to install the HealOps required module $requiredModule. It failed with > $_"
                }
            }
        }

        # Check that HealOps was installed
        $HealOpsModule = Get-Module -ListAvailable -All -Name $HealOpsModuleName
        $HealOpsModuleBase = (Get-Module -ListAvailable -All -Name $HealOpsModuleName).ModuleBase | Select-Object -Unique
        if ($HealOpsModule.Name -eq $HealOpsModuleName) {
            <#
                - The HealOps config json file.
            #>
            # Get Package Management repository info, to register it in the HealOps config json file
            try {
                $pmRepo = Get-PSRepository -Name $PackageManagementRepository
            } catch {
                throw "Could not get the package management repository specified. The update feature of HealOps might therefore not work. `
                Please make sure that you specified that this name $PackageManagementRepository is correct and that is has been registered."
            }

            Write-Progress -Activity "Installing HealOps" -CurrentOperation "Defining the HealOps config json file." -Id 3
            $HealOpsConfig = @{}
            $HealOpsConfig.reportingBackend = $reportingBackend

            !!! PackageManagementURI
            !!! FeedName
            !!! PackageManagementAPIKey

            $HealOpsConfig.packageManagementRepoName = $pmRepo.Name
            $HealOpsConfig.packageManagementRepoSrc = $pmRepo.ScriptSourceLocation
            $HealOpsConfig.packageManagementRepoPub = $pmRepo.PublishLocation
            $HealOpsConfig.packageManagementRepoScriptSrc = $pmRepo.ScriptSourceLocation
            $HealOpsConfig.packageManagementRepoScriptPub = $pmRepo.ScriptPublishLocation
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
                Set-Content -Path $HealOpsModuleBase/Artefacts/HealOpsConfig.json -Value $HealOpsConfig_InJSON -Force
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

            # Create the user
            $HealOpsUsername = "HealOps"
            try {
                $HealOpsUser = New-LocalUser -Name $HealOpsUsername -AccountNeverExpires -Description "Used to execute HealOps tests & repairs files." -Password $password -PasswordNeverExpires -UserMayNotChangePassword
            } catch {
                throw "Failed to create a batch user for HealOps. The error was > $_"
            }

            # Create credentials object used when registering the scheduled job.
            $credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $HealOpsUsername, $password

            # Add the user to the local privileged group. S-1-5-32-544 is the SID for the local 'Administrators' group.
            # TODO: needs to be specific to MacOS and linux at some point!
            try {
                Add-LocalGroupMember -SID S-1-5-32-544 -Member $HealOpsUser
            } catch {
                throw "Failed to add the HealOps batch user to the local 'Administrators' group. The error was > $_"
            }

            <#
                - Task for running HealOps
            #>
            try {
                Write-Progress -Activity "Installing HealOps" -CurrentOperation "Creating a task to execute HealOps." -Status "With these values > $TaskName, $TaskRepetitionInterval and $TaskPayload" -Id 5
                if ($psboundparameters.ContainsKey('FilePath')) {
                    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -TaskPayload "File" -FilePath $psboundparameters.FilePath -credential $credential
                } else {
                    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -TaskPayload "ScriptBlock" -ScriptBlock $psboundparameters.ScriptBlock -credential $credential
                }
            } catch {
                throw $_
            }

            <#
                - Clean-up
            #>
            # Remove the password variable from memory
            Remove-Variable Password -Force
            Remove-Variable credential -Force
            [System.GC]::Collect()
        } else {
            throw "The HealOps module does not seem to be installed. So we have to stop."
        }
    }
    End {}