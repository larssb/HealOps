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
    * Better building of HealOps
    * Deployment tactics
    * Tooling, meaning code, that can control a Package Management system for updates to a HealOps package.
        * And the well thought out logic flow of doing that and when....yeah yeah.
    * Tests and Repairs for 'X' systems.
        e.g.
        * Citrix prod.
        *
    * Create a Plaster template for easily creating a HealOpsPackage
    * Talk with the Linux DevOps about:
        * A good way to automatize creating Cron jobs.
    * Create the New-HealOpsPackageRunner script so that it takes pipeline input. In this case a string to a path....a path obj.???
    * Use jobs for executing multiple tests. In order to get to a less sequential approach.
        * Invoke-HealOps ready for the use of get-jobs and the like.

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