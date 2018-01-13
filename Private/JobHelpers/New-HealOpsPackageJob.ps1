function New-HealOpsPackageJob() {
<#
.DESCRIPTION
    Sets up a job that executes a *.Tests.ps1 file by invoking HealOps.
.INPUTS
    Inputs (if any)
.OUTPUTS
    [Bool] relative to the result of creating a job for the *.Tests.ps1 file specified.
.NOTES
    <none>
.EXAMPLE
    $result = New-HealOpsPackageJob -TestsBaseFileName $baseFileName -JobInterval $TestsFileJobInterval -JobType $JobType -Package $installedHealOpsPackage -Password $clearTextJobPassword -UserName $HealOpsUsername
        > Creates a job for the *.Tests.ps1 file specified. Via the provided parameters.
.PARAMETER JobInterval
    The interval at which to repeat the job.
.PARAMETER JobType
    The type of job to use when invoking HealOps.
.PARAMETER Package
    The name of the HealOps package that the job is created for.
        > [PSModuleInfo]
.PARAMETER Password
    The password set on the local HealOps user.
.PARAMETER TestsBaseFileName
    The name of the *.Tests.ps1 file that a job is created for. Without the file extension.
.PARAMETER UserName
    The username of the HealOps user.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword","")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The interval at which to repeat the job.")]
        [ValidateNotNullOrEmpty()]
        [int]$JobInterval,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The type of job to use when invoking HealOps.")]
        [ValidateSet('WinPSJob','WinScTask','LinCronJob')]
        [String]$JobType,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the HealOps package that the job is created for.")]
        [ValidateNotNullOrEmpty()]
        [psmoduleinfo]$Package,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The password set on the local HealOps user.")]
        [ValidateNotNullOrEmpty()]
        [String]$Password,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the *.Tests.ps1 file that a job is created for.
        Without the file extension.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsBaseFileName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The username of the HealOps user.")]
        [ValidateNotNullOrEmpty()]
        [String]$UserName
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        # Define the string that will interpreted by the job engine on the system and thereby invoke HealOps
        [String]$ScriptBlockString = "Invoke-HealOps -TestsFileName '$TestsBaseFileName' -HealOpsPackageName '$($Package.Name)'"

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
                    RepetitionInterval = (New-TimeSpan -Minutes $JobInterval)
                    RepeatIndefinitely = $true
                    Once = $true
                }
                try {
                    New-ScheduledJob -TaskName $TestsBaseFileName -TaskOptions $Options -TaskTriggerOptions $Trigger -TaskPayload "ScriptBlock" -ScriptBlock $ScriptBlockString -credential $credential -verbose
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
                        Password = $Password
                        PowerShellExeCommand = "$ScriptBlockString"
                        RunLevel = "Highest"
                        StartWhenAvailable = $true
                        User = $UserName
                    }

                    <#
                        Task trigger. The settings explained:
                            - RepetitionInterval: How often the task will be repeated.
                            - RepetitionDuration: For how long the task will keep on repeating. As programmed it will keep on going for over 9000 days.
                    #>
                    $kickOffJobDateTimeRandom = get-random -Minimum 2 -Maximum 6
                    $currentDate = ([DateTime]::Now)
                    $taskRunDuration = $currentDate.AddYears(25) - $currentDate
                    $Trigger = @{
                        At = (Get-date).AddMinutes(1).AddMinutes(($kickOffJobDateTimeRandom))
                        RepetitionInterval = (New-TimeSpan -Minutes $JobInterval)
                        RepetitionDuration  = $taskRunDuration
                        Once = $true
                    }

                    # Create the task via the PowerShell ScheduledTasks module.
                    try {
                        Add-ScheduledTask -TaskName $TestsBaseFileName -TaskOptions $Options -TaskTrigger $Trigger -Method "ScheduledTasks"
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
                    $executeFileFullPath = "$($Package.ModuleBase)/TestsAndRepairs/execute.$TestsBaseFileName.ps1"
                    $Options = @{
                        Username = $UserName
                        Password = $Password
                        ToRun = "`"powershell.exe -NoLogo -NonInteractive -WindowStyle Hidden -File `"`"$executeFileFullPath`"`"`""
                    }

                    <#
                        The settings explained:
                            - RepetitionInterval: How often the task will be repeated.
                    #>
                    $Trigger = @{
                        RepetitionInterval = $JobInterval
                    }

                    # Create a CMD file for the scheduled task to execute. In order to avoid the limitation of the /TR parameter on the schtasks cmd. It cannot be longer than 261 chars.
                    try {
                        Set-Content -Path "$executeFileFullPath" -Value "$ScriptBlockString" -Force -NoNewline -ErrorAction Stop
                    } catch {
                        throw "Failed to set content in the script for the scheduled task to execute. The task could there not be created for the Tests file > $TestsBaseFileName > You'll have to create a task manually for this test."
                    }

                    if (Test-Path -Path "$executeFileFullPath") {
                        try {
                            # Create the task with the schtasks cmd.
                            Add-ScheduledTask -TaskName $TestsBaseFileName -TaskOptions $Options -TaskTrigger $Trigger -Method "schtasks"
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
                #$jobResult = $true
                throw "not implemented yet.....Linux."
            }
            Default {
                $log4netLogger.error("None of the job types matched. Not good <> bad.")
                throw "None of the job types matched. The selected job type was > $JobType. Select a proper job type via the JobType parameter & try again."
            }
        }
    }
    End {}
} # End of function declaration.