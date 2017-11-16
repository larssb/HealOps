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
    <none>
.NOTES
    General notes
.EXAMPLE
    New-HealOpsTask -TaskName $TaskName -TaskRepetitionInterval $TaskRepetitionInterval -InvokeHealOpsFile $InvokeHealOpsFile
    Explanation of what the example does
.PARAMETER TaskName
    The name of the task.
.PARAMETER TaskRepetitionInterval
    The interval, in minutes, between repeating the task.
.PARAMETER InvokeHealOpsFile
    Specify the path to the file that is used to execute the HealOps package and its code. This file will then be called by the platforms job engine as scheduled.
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
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Specify the path to the file that is used to execute the HealOps package and its code.
        This file will then be called by the platforms job engine as scheduled.")]
        [ValidateNotNullOrEmpty()]
        [String]$InvokeHealOpsFile
    )

    #############
    # Execution #
    #############
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