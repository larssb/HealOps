# Status of the development of HealOps

## BUGS

    * Find a way to determine the locale of the system HealOps runs on. Use the PowerShellTooling module. In there, make a function that derives the locale of the system. If I'm correct Pester, PowerShellGet or something like that determines this <-- look there.
        * 1 can use Get-Culture
        * !!!! Right now I'm doing >  -replace ",.+","" -replace "\..+","" <-- as a workaround

    * Need to be able to support several It tests.
        * When there is more than 1 foreach iterate over the results. Or throw...see ibigservices haproxy test file.
        * Also, some tests can come back empty ... or throw as written in the above line.
        * !!!! If throwing and thereby stopping the execution of additional It assertion Pester checks, becomes the std. this needs to be described in the documentation.

    * Find a better way to load the module. Don't need export-modulemember on all functions. Just that there are exposed via the manifest. At least if it makes a difference in relation to this > #Requires -RunAsAdministrator --> in New-HealOpsTask <-- as it throws ==  : The script 'New-HealOpsTask.ps1' cannot be run because it contains a "#requires" statement for running as Administrator. The current Windows PowerShell session is not running as Administrator. Start Windows PowerShell by using the Ru.....

## Various

    - Look into https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-5.1

## Work

    * Call-graph over the flow of HealOps, from invocation and the outcomes of that.
    * Update architecture diagrams
        * Sequence for flow would especially be helpful.
    * Reporting
        * Good enough for RTM.
    * Create Pester tests for HealOps itself, that:
        * Tests the implicit axioms that can be derived from the description and documentation in the HealOps.ReadMe.md file.
    * Create tests for testing *.Tests.ps1 files.
        * Test > that every 'It' block contains a global variable named 'assertionResult'
    * Scheduled tasks helper scripts.
        * For Linux/MacOS
            * Find a good way to automatize creating Cron jobs.
    * Better build scripts of HealOps
        * Code coverage
        * Script Analyzer and so forth
    * Deployment tactics
            * If a required module is not installed get-module returns nothing, update-module could also react in weird ways. But aren't we sure that modules required by HealOps are instaled, if not HealOps wouldn't work at all. And! It should be a part of the bootstrap/install of HealOps to install required modules.
    * Program function that can > Cache and queue reports on “X” IT service. In case of the reporting backend being down or that it is not possible to reach it.
    * RunningAsScheduledTask
        - ByPass needed
            --> Set that on the registered job.
        - Must be a full path in the command in the task -scriptblock object.
            --> Could likely be solved in the same way as in Update-TestRunningStatus. So that the 1 installing does not have to think about that.
    * __Ongoing verifications and test__
        * Will it be an issue that an update could be started by several jobs at the same time?
            * Hmm as long as the jobs do not start at the same time we should be okay.
    * Think about doing a simple health svc for HealOps. So that you can ask HealOps from the outside if it is a okay...or have HealOps simply report that it is running on each invoke-healops call. Hmmm hm hmmmm!
    * Think about how we can make sure that peeps configure the config file in the HealOps packages used on a system.
        * At least catch it if there is empty properties in the config
            * Maybe set an "UNKNOWN" value or "NOT_SET"
    * If HealOps is run in headless mode....provide write-output or write-host messages...same messages as for errors where applicable.
    * # The update cycle did not run. It could have failed or the time criteria was not met. Set to the same time of checkForUpdatesNext > in order to have HealOps run an update cycle again.
        * Do not need to update HealOps config json every freaking time?
    * Install-HealOps
        * Job for each tests file
        * Random start
        * Repeat unique for each
        * Config in HealOps package json file.
    * CATCH errors on submit-entitystatereport....
        * Have fallback so that it can be caught that reporting does not work. E.g. something that reports:
            * Node = (we already get that when HealOps run)
            * to metric x.y.z that > we look at in Grafana
    * Think about deleting old version of an updated module. Cannot be done in the same session that updated HealOps itself.
        Maybe do a contorl on $MyInvocation --> if latest version --> remove older than newest/current. If not latest do nothing as we likely just updated.
    * Make the Git pre-commit compatible with version 5.1 and 6+. Where the executable in v5.1- is PowerShell and v6+ is PWSH.

## Think about

    * A proper way of determining or specifying the environment on which HealOps is runing and thereby tests
    executed.
        * Should it be configured?
            * Could be a part of a HealOpsPackage.
        * ...or should HealOps "intelligently" figure it out? Is that possible at all.

    * The proper way of monitoring HealOps itself. It can report on a lot of things internally. But what is the clever way?
        * Exceptions
        * Different cornercases
    - See under ## Work

    * Should we have a general report/status feature in HealOps. <-- definetely later but still.

    * Metrics to get:
        * TTLB (Time to last byte)
        * Exceptions
        * Perf. counters
            * custom as well