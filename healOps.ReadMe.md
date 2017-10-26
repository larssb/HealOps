# ReadMe

## Setup and configuration of HealOps

1 Create a *.ps1 file

    * A good naming convention would be "healOps_"NAME_OF_SERVICE_AKA_ENTITY".ps1"
    * Call invoke-healops from this file.
        * With the relevant values in relation to the IT Service/Entity to invoke HealOps on.
            * Here is an example of how it could look.
            `

            `
    * Use the New-HealOpsTaks cmdlet to create a job for invoking HealOps on the IT Service/Entity
        * Refer to the file you created in step (1).

## Repairing

1 The ID of a repair to run must match the order of the tests in a *.Tests.ps1 file.

    * The order of tests follows a top-down hierarchy.
        * The top test in a *.Tests.ps1 file has ID == 1
        * The following test will then have ID == 2 and so forth for any remaining tests.

2 An axiom is that *.Repairs.ps1 files is located next to the *.Tests.ps1 file.

    * And...it the names for the *.Tests.ps1 and *.Repairs.ps1 files should match. Meaning:
        * File "F" > sitecore.Tests.ps1 have a corresponding >
        * File "F" > sitecore.Repairs.ps1.

### The *.Repairs.ps1 file

1 A *.Repairs.ps1 file is a JSON format complaint file

    * Here is an example:
`
{
    "ServiceItRepairs": "X",
    "Repairs": [
        {
            "id": 1,
            "name": "N",
            "powershellCode": ""
        }
    ]
}
`