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

    - The name of DS packagement and URI
        * "checkForUpdates_Repository":  "dsPowerShellModules",
        * "checkForUpdates_URI":  "http://teamcity.danskespil.dk:8082/nuget/dsPowerShellModules/",

    - Look into https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-modulemanifest?view=powershell-5.1

## Work

    * Call-graph over the flow of HealOps, from invocation and the outcomes of that.
    * Updated diagrams
        * Sequence for flow would especially be helpful.
    * Reporting
    * Create Pester tests for HealOps itself, that:
        * Tests the implicit axioms that can be derived from the description and documentation in the HealOps.ReadMe.md file.
    * Create tests for testing *.Tests.ps1 files.
        * Test > that every 'It' block contains a global variable named 'assertionResult'
    * Scheduled tasks helper scripts.
        * For Windows <-- Working, needs fine-tuning and support for defining job executing user.
        * For Linux/MacOS
    * Better build scripts of HealOps
        * Code coverage
        * Script Analyzer and so forth
    * Deployment tactics
    * Tooling, meaning code, that can control a Package Management system for updates to a HealOps package.
        * Hardening
            * If a required module is not installed get-module returns nothing, update-module could also react in weird ways. But aren't we sure that modules required by HealOps are instaled, if not HealOps wouldn't work at all. And! It should be a part of the bootstrap/install of HealOps to install required modules.
    * Tests and Repairs for 'X' systems.
        e.g.
        * Citrix prod.
        *
    * Create a Plaster template for easily creating a HealOpsPackage
    * Talk with the Linux DevOps about:
        * A good way to automatize creating Cron jobs.
    * Create the New-HealOpsPackageRunner script so that it takes pipeline input. In this case a string to a path....a path obj.???
    * Program function that can > Cache and queue reports on “X” IT service. In case of the reporting backend being down or that it is not possible to reach it.
    * RunningAsScheduledTask
        - ByPass needed
            --> Set that on the registered job.
        - Must be a full path in the command in the task -scriptblock object.
        - PowerShellGet version:
            --> 1.5.0.0
            --> Therefore > Install-Module -Name PowerShellGet -Force
            --> Upload to PackageManagement system
    * Fix error on Update-TestRunningStatus:
        * En del af stien 'C:\Users\HealOps\Documents\LABE\gitRepos\HealOpsPackages\Sitecore\TestsAndRepairs\system.resource.disk
        space.Status.json' blev ikke fundet.
            + CategoryInfo          : ObjectNotFound: (C:\Users\HealOp...ace.Status.json:String) [Set-Content], DirectoryNotFo
        undException
            + FullyQualifiedErrorId : GetContentWriterDirectoryNotFoundError,Microsoft.PowerShell.Commands.SetContentCommand
            + PSComputerName        : localhost
        * Set-content -erroraction Stop inside Update-TestRunningStatus! To catch the error.

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