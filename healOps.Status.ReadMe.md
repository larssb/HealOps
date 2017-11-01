# Status of the development of HealOps

## Prioritized work

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