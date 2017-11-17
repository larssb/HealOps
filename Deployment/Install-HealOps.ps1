<#PSScriptInfo

.VERSION 0.0.0.3

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
    If not interval is defined for the checkForUpdatesInterval_InDays parameter Install-HealOps will default to 7 a day interval.
.EXAMPLE
    "PATH_TO_THIS_FILE"/Instal-HealOps.ps1 -reportingBackend $reportingBackend -TaskName "MyHealOpsTask" -TaskRepetitionInterval 3 -
    Explanation of what the example does
.PARAMETER reportingBackend
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER checkForUpdates
    Whether to enable the check for updates feature or not.
.PARAMETER checkForUpdatesInterval_InDays
    The interval in days between checking for updates
.PARAMETER PackageManagementRepository
    The name of the repository on the Package Management system
.PARAMETER TaskName
    The name of the task.
.PARAMETER TaskRepetitionInterval
    The interval, in minutes, between repeating the task.
.PARAMETER TaskPayload
    The type of payload to invoke HealOps with.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('OpenTSDB')]
        [String]$reportingBackend,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Whether to enable the check for updates feature or not.")]
        [Switch]$checkForUpdates,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the repository on the Package Management system.")]
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
        [String]$TaskPayload
    )

    DynamicParam {
        #if($checkForUpdates -eq $true) {
            # Check for updates functionality switch used. Set the needed parameters to configure the feature
            <#
                - checkForUpdatesInterval_InDays param.
            #>
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute
            $attributes.Mandatory = $false
            $attributes.HelpMessage = "The interval in days between checking for updates."
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $checkForUpdatesInterval_InDays_ParameterName = "checkForUpdatesInterval_InDays"
            [Type]$ParameterType = "Int"
            $checkForUpdatesInterval_InDays_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($checkForUpdatesInterval_InDays_ParameterName, $ParameterType, $AttributeCollection)
            if ($null -eq $checkForUpdatesInterval_InDays_Parameter.Value) {
                # No value was provided, fallback to once a week.
                $checkForUpdatesInterval_InDays_Parameter.Value = 7
            }

            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add($checkForUpdatesInterval_InDays_ParameterName, $checkForUpdatesInterval_InDays_Parameter)

            return $paramDictionary
        #}

        if($TaskPayload -eq "File") {
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute
            $attributes.Mandatory = $true
            $attributes.HelpMessage = "The full path to the file that the Windows Scheduled Task should execute when triggered."
            #$ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            #$attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $TaskPayloadFilePath_ParameterName = "FilePath"
            [Type]$ParameterType = "String"
            $TaskPayloadFilePath_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($TaskPayloadFilePath_ParameterName, $ParameterType, $AttributeCollection)

            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add($TaskPayloadFilePath_ParameterName, $TaskPayloadFilePath_Parameter)
            return $paramDictionary
        } elseif($TaskPayload -eq "ScriptBlock") {
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute
            $attributes.Mandatory = $true
            $attributes.HelpMessage = "The scriptblock that the scheduled task should execute when triggered."
            #$ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            #$attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $TaskPayloadScriptBlock_ParameterName = "ScriptBlock"
            [Type]$ParameterType = "String"
            $TaskPayloadScriptBlock_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($TaskPayloadScriptBlock_ParameterName, $ParameterType, $AttributeCollection)

            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add($TaskPayloadScriptBlock_ParameterName, $TaskPayloadScriptBlock_Parameter)
            return $paramDictionary
        }


    }

    #############
    # Execution #
    #############
    Begin {
        <#
            - Sanity tests
        #>

        <#
            - Define variables and other needed data
        #>
        # The name of the HealOps module.
        $HealOpsModuleName = "HealOps"
    }
    Process {
        <#
            - Install HealOps and its required modules.
        #>
        # Register the repository
        try {
            #Register-PSRepository -Name $PackageManagementRepository -SourceLocation $PackageManagementURI -PublishLocation $PackageManagementURI
        } catch {
            throw "register-psrepo...failed with > $_"
        }

        # Install HealOps
        try {
            Install-Module -Name $HealOpsModuleName -Repository $PackageManagementRepository -ErrorAction Stop -ErrorVariable installModuleEV
        } catch {
            throw "Install-Module...failed with > $_"
        }

        # Installation of HealOps required modules
        if ($null -eq $installModuleEV) {
            # Get the required modules from the installed HealOps module
            $requiredModules = (Get-Module -All -Name $HealOpsModuleName).RequiredModules

            # Install the modules
            foreach ($requiredModule in $requiredModules) {
                try {
                    Install-Module -Name $requiredModule -Repository $PackageManagementRepository -ErrorAction Stop
                } catch {
                    throw "Failed to install the HealOps required module $requiredModule. It failed with > $_"
                }
            }
        }

        # Check that HealOps was installed
        $HealOpsModule = Get-Module -All -Name $HealOpsModuleName
        if ($HealOpsModule.Name -eq $HealOpsModuleName) {
            <#
            - The HealOps config json file.
            #>
            $HealOpsConfig = @{}
            $HealOpsConfig.reportingBackend = $reportingBackend
            $HealOpsConfig.checkForUpdates = $checkForUpdates
            if($checkForUpdates -eq $true) {
                $HealOpsConfig.checkForUpdatesNext = "" # Real value provided when HealOps is running and have done its first update cycle pass.
                $HealOpsConfig.checkForUpdatesInterval_InDays = $psboundparameters.checkForUpdatesInterval_InDays
            }

            # Convert to JSON
            $HealOpsConfig_InJSON = ConvertTo-Json -InputObject $HealOpsConfig -Depth 3
            Write-Verbose -Message "HealOpsConfig JSON to write to the HealOpsConfig json file > $HealOpsConfig_InJSON"

            # Write the HealOps config json file
            ## TODO: Figure out the location of the PowerShell modules path. Inspiration can be picked up in the PowerShellGet module on GitHub
            try {
                Set-Content -Path "C:\Program Files\WindowsPowerShell\Modules\HealOps\Artefacts\HealOpsConfig.json" -Value $HealOpsConfig_InJSON -Force
            } catch {
                throw "Writing the HealOps config json file failed with: $_"
            }

            <#
                - Task for running HealOps
            #>
            try {
                if ($psboundparameters.ContainsKey('FilePath')) {
                    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -TaskPayload "File" -FilePath $FilePath
                } else {
                    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -TaskPayload "ScriptBlock" -ScriptBlock $ScriptBlock
                }
            } catch {
                throw $_
            }
        } else {
            throw "The HealOps module does not seem to be installed. So we have to stop."
        }
    }
    End {}
