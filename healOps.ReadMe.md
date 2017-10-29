# HealOps ReadMe

## Deploying HealOps

1 When deploying HealOps to a node you will need to deploy:

    * The specific HealOps package for the IT Service/Entity you want to monitor and heal.
    * The HealOps module itself.

## Repairing

Repairing works when:

    * There is one test in each *.Tests.ps1 file.
    * Each *.Tests.ps1 file have a matching *.Repairs.ps1 file. E.g.
        * File "F" > iisLogs.Tests.ps1 have a corresponding >
        * File "F" > iisLogs.Repairs.ps1.
    * These two files needs to be located next to each-other.

## Reporting

### Naming scheme

The std. is:

    * Needed values:
        * Name of the IT Service/Entity.
        * Component/part of the IT service/Entity that was tested.
        * Sub-component/Resource of the component/part of the IT service/Entity that was tested.
        * Tags >

    __e.g. >__ ``

## Setup and configuration of HealOps

1 Create a *.ps1 file

    * A good naming convention would be "healOps_"NAME_OF_SERVICE_AKA_ENTITY".ps1"
    * Call the invoke-healops function from this file.
        * With the relevant values in relation to the IT Service/Entity to invoke HealOps on.
            * Here is an example of how it could look.
            `

            `
        * Call it [n] times. One time per. IT Service/Entity you wish to validate state for.
    * Use the New-HealOpsTaks cmdlet to create a job for invoking HealOps on the IT Service/Entity
        * Refer to the file you created in step (1).

### The *.Repairs.ps1 file

1 Naming:

    * Function name: Use the following verb. = Repair-
    * Function name: the rest of the function name should be named after what it repairs. Typically a good name would be the name of the *.Repairs.ps1 file that is specific to the IT Service/Entity in question.
        * E.g. = Repair-octopusTentacle where octopusTentacle <-> octopusTentacle.Repairs.ps1