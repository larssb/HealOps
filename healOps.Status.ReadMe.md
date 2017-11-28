# Status of the development of HealOps

## BUGS

    * Find a way to determine the locale of the system HealOps runs on. Use the powerShellTooling module. In there do a function that derives the locale of the system. If I'm correct Pester, PowerShellGet or something like that determines this <-- look there.
        * 1 can use Get-Culture
        * !!!! Right now I'm doing >  -replace ",.+","" -replace "\..+","" <-- as a workaround

    * Need to be able to support several It tests.
        * When there is more than 1 foreach iterate over the results. Or throw...see ibigservices haproxy test file.
        * Also, some tests can come back empty ... or throw as written in the above line.
        * !!!! If throwing and thereby stopping the execution of additional It assertion Pester checks, becomes the std. this needs to be described in the documentation.

    * Find a better way to load the module. Don't need export-modulemember on all functions. Just that there are exposed via the manifest. At least if it makes a difference in relation to this > #Requires -RunAsAdministrator --> in New-HealOpsTask <-- as it throws ==  : The script 'New-HealOpsTask.ps1' cannot be run because it contains a "#requires" statement for running as Administr
tor. The current Windows PowerShell session is not running as Administrator. Start Windows PowerShell by  using the Ru.....

## Various

    - The name of the DS package management endpoint and URI
        * "checkForUpdates_Repository":  "dsPowerShellModules",
        * URI >  https://proget.danskespil.dk/nuget/dsPowerShellModules/

    - Look into https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-5.1

    - The name of the DS HealOps package management endpoint and URI
        * name > dsHealOpsPackages
        * URI > https://proget.danskespil.dk/nuget/dsHealOpsPackages/

## Work

    * Call-graph over the flow of HealOps, from invocation and the outcomes of that.
    * Updated diagrams
        * Sequence for flow would especially be helpful.
    * Reporting
        * Good enough for RTM.
    * Create Pester tests for HealOps itself, that:
        * Tests the implicit axioms that can be derived from the description and documentation in the HealOps.ReadMe.md file.
    * Create tests for testing *.Tests.ps1 files.
        * Test > that every 'It' block contains a global variable named 'assertionResult'
    * Scheduled tasks helper scripts.
        * For Linux/MacOS
            * Talk with the Linux DevOps about: A good way to automatize creating Cron jobs.
    * Better build scripts of HealOps
        * Code coverage
        * Script Analyzer and so forth
    * Deployment tactics
    * Tooling, meaning code, that can control a Package Management system for updates to a HealOps package.
        * Hardening
            * If a required module is not installed get-module returns nothing, update-module could also react in weird ways. But aren't we sure that modules required by HealOps are instaled, if not HealOps wouldn't work at all. And! It should be a part of the bootstrap/install of HealOps to install required modules.
    * Create a Plaster template for easily creating a HealOpsPackage
        * WIP but update with the latest. 171121. After creating Sitecore HealOps package as a module.
    * Create the New-HealOpsPackageRunner script so that it takes pipeline input. In this case a string to a path....a path obj.???
    * Program function that can > Cache and queue reports on “X” IT service. In case of the reporting backend being down or that it is not possible to reach it.
    * RunningAsScheduledTask
 ¤¤       - ByPass needed
            --> Set that on the registered job.
        - Must be a full path in the command in the task -scriptblock object.
            --> Could likely be solved in the same way as in Update-TestRunningStatus. So that the 1 installing does not have to think about that.
    * NEED to have it allowed on AD level that the HealOps account is allowed to stay in the local "Administrators" group.
        * Gives --> 2147943785 event id 101 if not. "Log on as a batch job" issue.
    * __Ongoing verifications and test__
        * That the self-update feature works as intended.
            * For both HealOps itself as well as the HealOps packages.
        !! Issue found. When updating the version number under the modules folder will change. This makes the path in the Scheduled Task invalid. How do we fix that?
        !! When bootstrapping HealOps...on first run. A Package Management repo./endpoint needs to be registered. If not the exception > ' The variable '$psgetItemInfo' cannot be retrieved because it has not been set. ' is thrown.
            The error: `
 ¤¤               The variable '$psgetItemInfo' cannot be retrieved because it has not been set.
                At C:\Program Files\WindowsPowerShell\Modules\PowerShellGet\1.5.0.0\PSModule.psm1:289 char:136
                + ... odulewhatIfMessage -replace "__OLDVERSION__",$($psgetItemInfo.Version ...
                +                                                    ~~~~~~~~~~~~~~
                    + CategoryInfo          : InvalidOperation: (psgetItemInfo:String) [], RuntimeException
                    + FullyQualifiedErrorId : VariableIsUndefined
            `
            -- We should be able to catch that in some way >> if that exception is thrown >> not set the checkForUpdatesNext property in the HealOpsConfig.json file.
                > The Fix >>> to register a psrepo. !!! ASK on the PowerShellGet GitHub repo. why this is???????
        * Will it be an issue that an update could be started by several jobs at the same time?
            * Hmm as long as the jobs do not start at the same we should be okay.
    * Think about doing a simple health svc for HealOps. So that you can ask HealOps from the outside if it is a okay...or have HealOps simply report that it is running on each invoke-healops call. Hmmm hm hmmmm!
    * Think about how we can make sure that peeps configure the config file in the HealOps packages used on a system.
        * At least catch it if there is empty properties in the config
            * Maybe set an "UNKNOWN" value or "NOT_SET"
    * If HealOps is run in headless mode....provide write-output or write-host messages...same messages as for errors where applicable.
    * # The update cycle did not run. It could have failed or the time criteria was not met. Set to the same time of checkForUpdatesNext > in order to have HealOps run an update cycle again.
        * Do not need to update HealOps config json every freaking time.
    * This error > '$script:PSGetModuleSourcesFilePath' seems to occur because this `
        $script:PSGetAppLocalPath="$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet"
        $script:PSGetModuleSourcesFilePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetAppLocalPath -ChildPath "PSRepositories.xml"
    ` cannot be resolved by the PowerShellGet module.
        * Think about a good solution
    * This error: `
    PS C:\> Receive-Job -Id 56 -Keep
The 'Invoke-HealOps' command was found in the module 'HealOps', but the module could not be loaded. For more informatio
n, run 'Import-Module HealOps'.
    + CategoryInfo          : InvalidResult: (:) [], RemoteException
    + FullyQualifiedErrorId : ScheduledJobFailedState
    `
        * Can be solved by doing "Import-Module HealOps -Force; Invoke-HealOps....." in the scriptblock to the module.
    * BUT THE MOFO problem is > that jobs is crashing after no time when started with a PowerShell scheduled job.
        * Do a test with just one test file....
        * Fix try/catch and logging for that scenario before getting going.
    * When there is two versions of PowerShellGet if fucks up in headless mode. So --> have to remove any versions below the 1 required by HealOps.
        * That version is likely not installed with PowerShellGet....remove the folder by deleting it
            * Check on this with > uninstall-module .... catch error
        * Ask why somewhere!
    * Looks like PowerShellGet does not support headless mode.
        * Soon as I remove that from the required modules I do not get the invoke-healops cmdlet was not found error.
    * Install-HealOps
        * Job for eact tests file
        * Random start
        * Repeat unique for each
        * Config in HealOps package json file.
    * CATCH errors on submit-entitystatereport....
        * Have fallback so that it can be caught that reporting does not work. E.g. something that reports:
            * Node = (we already get that when HealOps run)
            * to metric x.y.z that > we look at in Grafana

TWO ISSUES NOW
    * Self-update feature
    * Using Start-job with/inside PowerShell scheduled jobs....is it supported and is it a good idea anyway.
        * Multiple instances....and 1 5min. job could run and run and the others will just be kickstarted.
        * But why not just have 1 scheduled job per tests file? Could be creatd with the install-healops script. And you could have people define the repeat interval in the
        HealOpsPackage config json file.
            * Because setting the repetition interval to one size fit for all is it good anyways? Not likely. Because:
                --> 5min everything started all tests invoked
                --> wait 5min try again
                INSTEAD OF
                --> repetition per created scheduled job
            * Would also simplify the code.
    * Tried with Packagemanagement, seems like it has the same issues. Asked in their repo. on Github. Waiting for an answer.
        * !!!!!!!!!!!!! FDAD#R=)#(R=)(R=) --> Alternatively, look into if it is possible to fetch from a PackageManagent repo via invoke-webrequest.....and so on
        ALTERNATIVES:
            * https://github.com/joel74/POSH-ProGet-API
            *

    * TOMORROW
        * Think about deleting old version of an updated module. Cannot be done in the same session that updated
            Måske noget kontrol på $MyInvocation --> if latest version --> remove older than this. If not latest do nothing as we likely just updated.
                ** Hvis ovenstående er vejen. Ud i selvstændig funktion.
        * Test self-update feature i headless mode når der er kommet styr på ovenstående
        * Delete HealOps from Froome2a town1
            -- everything that Install-HealOps do
        * Fix run PowerShell with -ExecutionPolicy Bypass hvis nødvendigt...

## Think about

    * Splitting the repo into two.
        * 1 for the core HealOps module.
        * another for HealOps packages. These packages are the packages containing *.Repairs.ps1 and *.Tests.ps1 files that are invoked when testing state of service "S" and when trying to remediate "S". Implicitly therefore all the code necessary to test and remediate "S".

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
        * Danskespil.dk sub-sites
        * Exceptions
        * Perf. counters
            * custom as well

    * Saving lookups in the test running status checks. By. Could have a tests[[]] in the HealOps package config....to MAYBE save a lookup.