# Status of the development of HealOps

## BUGS

    * Find a way to determine the locale of the system HealOps runs on. Use the powerShellTooling module. In there do a function that derives the locale of the system. If I'm correct Pester, PowerShellGet or something like that determines this <-- look there.
        * 1 can use Get-Culture
        * !!!! Right now I'm doing >  -replace ",.+","" -replace "\..+","" <-- as a workaround

    * Need to be able to support several It tests.
        * When there is more than 1 foreach iterate over the results. Or throw...see ibigservices haproxy test file.
        * Also, some tests can come back empty ... or throw as written in the above line.
        * !!!! If throwing and thereby stopping the execution of additional It assertion Pester checks, becomes the std. this needs to be described in the documentation.

    * in repair-entitystate > $repairsFile = $TestFilePath -replace "Tests","Repairs"
        * This line blows if there is actually a folder in the path that is named Tests. See if we can hit only the filename
        part of the path ... bam! Even though it is not the described folder structure in the documentation.

## Work

    * Call-graph over the flow of HealOps, from invocation and the outcomes of that.
    * Updated diagrams
        * Sequence for flow would especially be helpful.
    * Reporting
    * Create Pester tests for HealOps itself, that:
        * Tests the implicit axioms that can be derived from the description and documentation in the HealOps.ReadMe.md file.
    * Create tests for testing *.Tests.ps1 files.
        * Test > that every 'It' block contains an global variable named 'assertionResult'
    * To derive system name:
        SUGGESTION 1: Use the description under Metrics in the HealOps.ReadMe.md file -> systemName.SystemComponent.SystemSubComponent.(SystemSubComponent)
        * Control that there is at least one 'dot/.' in the name.
        * Parse the name and get the sub-string up until the first dot.
        * ...maybe assume no systemname if there isn't at least one 'dot/.'.

        SUGGESTION 2: Use a healopspackage.packageSpecificName.json file for specifying stuff like systemName/Environment

        SUGGESTION 3: Use a global variable inside the *.Tests.ps1 file.
    * Scheduled tasks helper scripts.
        * For Windows
        * For Linux/MacOS
    * Better building of HealOps
    * Deployment tactics
    * Tooling, meaning code, that can control a Package Management system for updates to a HealOps package.
        * And the well thought out logic flow of doing that and when....yeah yeah.
    * Tests and Repairs for 'X' systems.
        e.g.
        * Citrix prod.
        *

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