function New-HealOpsTask() {
<#
.DESCRIPTION
    New-HealOpsTask is used to create either:
        a) a "Scheduled Taks" if OS == Windows or
        b) a "cron" job if OS == Linux or MacOS

    The function determines on its own, the OS it is executed on and thereby whether to create a cron job or a Scheduled Task
.INPUTS
    <none>
.OUTPUTS
    [Boolean] relative to the result of trying to create a HealOps task.
.NOTES
    General notes
.EXAMPLE
    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -InvokeHealOpsFile $InvokeHealOpsFile
    Explanation of what the example does
.PARAMETER TaskName
    The name of the task.
.PARAMETER TaskRepetitionInterval
    The interval, in minutes, between repeating the task.
.PARAMETER TaskPayload
    The type of payload to invoke HealOps with.
.PARAMETER FilePath
    - If the payload type is "File".
    Specify the path to the file that is used to execute the HealOps package and its code. This file will then be called by the platforms job engine as scheduled.
.PARAMETER ScriptBlock
    - If the payload type is "ScriptBlock".
    String representing the cmdline that HealOps should invoke. E.g. > Invoke-HealOps -TestsFilesRootPath "PATH_TO_THE_FOLDER_CONTAINING_TESTS_FILES" -HealOpsPackageConfigPath "PATH_TO_THE_FOLDER_CONTAINING_HealOpsConfig.json"
.PARAMETER credential
    The credential of the user that should execute the HealOps task.
.PARAMETER JobType
    The type of job to use for invoking HealOps.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the task.")]
        [ValidateNotNullOrEmpty()]
        [String]$TaskName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The interval, in minutes, between repeating the task.")]
        [ValidateNotNullOrEmpty()]
        [Int]$TaskRepetitionInterval,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of payload the task should execute when triggered.")]
        [ValidateSet('File','ScriptBlock')]
        [String]$TaskPayload,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The credentials of the user that should execute the HealOps task.")]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$credential,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of job to use for invoking HealOps.")]
        [ValidateSet('WinPSJob','WinScTask','LinCronJob')]
        [String]$JobType
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
            $attributes.HelpMessage = "The full path to the file that the Windows Scheduled Task should execute when triggered."
            $ParameterName = "FilePath"
        } elseif($TaskPayload -eq "ScriptBlock") {
            $attributes.HelpMessage = "The scriptblock that the scheduled task should execute when triggered."
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
    Begin{}
    Process {
        # Determine the operating system
        <#if () {

        }#>

        <#
            The settings explained:
            - Be shown in the Windows Task Scheduler
            - Start if the computer is on batteries
            - Continue if the computer is on batteries
            - If the job is tried started manually and it is already executing, the new manually triggered job will queued
        #>
        $jobOptionsSplatting = @{
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
        $jobTriggerSplatting = @{
            At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom)).ToString();
            RepetitionInterval = (New-TimeSpan -Minutes $TaskRepetitionInterval);
            RepeatIndefinitely = $true;
            Once = $true;
        }

        switch ($JobType) {
            "WinPSJob" {
                try {
                    if ($psboundparameters.ContainsKey('FilePath')) {
                        New-ScheduledJob -TaskName $TaskName -TaskOptions $jobOptionsSplatting -TaskTriggerOptions $jobTriggerSplatting -TaskPayload "File" -FilePath $psboundparameters.FilePath -credential $credential -verbose
                    } else {
                        New-ScheduledJob -TaskName $TaskName -TaskOptions $jobOptionsSplatting -TaskTriggerOptions $jobTriggerSplatting -TaskPayload "ScriptBlock" -ScriptBlock $psboundparameters.ScriptBlock -credential $credential -verbose
                    }
                } catch {
                    throw $_
                }
            }
            "WinScTask" {
                #
                try {
                    Add-ScheduledTask -TaskName $TaskName

                } catch {
                    throw $_
                }
            }
            "LinCronJob" {
                Write-Output "Linux cron job feature has not been added yet."
                break
            }
        }
    }
    End{}
}