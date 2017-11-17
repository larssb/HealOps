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
        [String]$TaskPayload
    )

    DynamicParam {
        $attributes = new-object System.Management.Automation.ParameterAttribute
        if($TaskPayload -eq "File") {
            # Configure parameter
            $attributes.Mandatory = $true
            $attributes.HelpMessage = "The full path to the file that the Windows Scheduled Task should execute when triggered."
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $ParameterName = "FilePath"
            [Type]$ParameterType = "String"
        } else {
            # Configure parameter
            $attributes.Mandatory = $true
            $attributes.HelpMessage = "The scriptblock that the scheduled task should execute when triggered."
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $ParameterName = "ScriptBlock"
            [Type]$ParameterType = "String"
        }

        $Parameter = New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, $ParameterType, $attributeCollection)
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add($ParameterName, $Parameter)
        return $paramDictionary
    }

    #############
    # Execution #
    #############
    Begin{}
    Process{
        <# Validate that the file exists at the specied path
        if ((Test-Path -Path $InvokeHealOpsFile)) {

        }#>

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
        $jobTriggerSplatting = @{
            At = (Get-date).AddMinutes(5);
            RepetitionInterval = (New-TimeSpan -Minutes $TaskRepetitionInterval);
            RepeatIndefinitely = $true;
            Once = $true;
        }

        # Create the job with the above options
        try {
            New-ScheduledJob -TaskName $TaskName -TaskOptions $jobOptionsSplatting -TaskTriggerOptions $jobTriggerSplatting -TaskPayload "File" -FilePath $InvokeHealOpsFile -verbose
        } catch {
            throw "Failed to create the HealOps task. The error is > $_"
        }
    }
    End{}
}