# Troubleshooting HealOps and HealOps packages

## Logs

The initial location to go-to is the logs. A logfile is created for each StatsFile and TestsFile being executed. The log location is relative to the newest version of the installed HealOps module and the system default global PowerShell module intallation path. More specifically. If HealOps v1.1.0 then log files will be saved to `%SystemDrive%:\Program Files\WindowsPowerShell\Modules\HealOps\1.1.0\Artefacts` on _Windows_. On MacOS and Linux the log location will `_PowerShellGlobalModuleInstallationFolder_/Modules/HealOps/1.1.0/Artefacts`.

An invocation of a HealOps Stats or Tests file via a triggered job is annotated with:

```PowerShell
[18-09-17 00:03:57] [Time since execution start (in ms): 124] [DEBUG] - --------------------------------------------------
[18-09-17 00:03:57] [Time since execution start (in ms): 124] [DEBUG] - ------------- HealOps logging started ------------
[18-09-17 00:03:57] [Time since execution start (in ms): 124] [DEBUG] - ------------- 17-09-2018 00:03:57 -----------
[18-09-17 00:03:57] [Time since execution start (in ms): 124] [DEBUG] - --------------------------------------------------
```

...this makes it easy to spot when the current execution of a HealOps Stats or Tests file was started. And thereby from where in the file you should start logging for the error culprit.

### Logging

If you are developing a HealOps package, or "just" extending one with new Stats and/or Tests files, it is possible to use the logging system of HealOps. In this way you can log specific errors and debug info if you are having issues with getting something to work.
You do this by using the __global__ variable named `$log4netLogger` to log definite errors and the __global__ variable named `$log4netLoggerDebug` to log debug information. Here is some specific examples.

**_Debug information_**

```PowerShell
$log4netLoggerDebug.Debug("No NIC named 'Im not here' was found on this server.")
```

Notice the `.Debug` method on the `$log4netLoggerDebug` object. You have to use this in order to debug log.

**_Definite errors_**

```PowerShell
$log4netLogger.error("Failed to restart the NIC on the server. Failed with $_.")
```

Notice the `.error` method on the `$log4netLogger` object. You have to use this in order to error log. You would usually have the call to $log4netLogger.error inside a `try {} catch` statement.

## Jobs

### Scheduled tasks (Windows)

A scheduled task can fail. Below you find some tips and guidelines on how-to troubleshoot such issues.

* Use the `History` tab of the `Task Scheduler` tool. Use your favourite searchmachine on the error id of a failed task.
* Often the root cause is something silly. Like the user executing the task not having the correct permissions. Try some of these when in trouble.
        * Try executing the `action` of the scheduled task manually in a PowerShell shell. In that way you can follow the execution as it goes. Maybe you spot what is wrong.
        * Ensure the user running the task has the proper permissions on the system where the task is being executed.
        * Re-create the task. Delete it and start over.