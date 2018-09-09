# Developing a HealOpsPackage

__The easy way to get going__

1. If `Plaster` isn't already installed on your box then install it: `Install-Module -Name Plaster -Repository PSGallery`
2. Execute `Invoke-Plaster`. For an example _see the below video, showing the effects of running Invoke-Plaster to create a HealOpsPackage_.

[![video](https://asciinema.org/a/t4jqseGsOx1xtxQesIZaLss1B.png)](https://asciinema.org/a/t4jqseGsOx1xtxQesIZaLss1B)

> The video uses the HealOpsPackage template found in the [PlasterPlethora](https://github.com/larssb/PlasterPlethora) GitHub repository.

__The cumbersome way__

If you for some reason (which is hard to fathom), do not want to use the Plaster PowerShell module, you need to follow the below guide to get going.

1. Create the following folder structure.
```txt
THE_NAME_OF_THE_HealOpsPackage > It will be the root folder
└───Config > Contains the configuration file for the HealOpsPackage.
└───Stats > Contains the *.Stats.ps1 files, used to report metric stats data on an IT System or component.
└───TestsAndRepairs > Contains the *.Tests.ps1 (Pester test files) and the *.Repairs.ps1 files.
```
2. Create the following files.
```txt
THE_NAME_OF_THE_HealOpsPackage > The root folder
└───*.HealOpsPackage.psd1 > The HealOpsPackage PowerShell module manifest file.
└───*.HealOpsPackage.ReadMe.md > A ReadMe markdown file explaining what the HealOps package contains and do.
└───Config
└──────THE_NAME_OF_THE_HealOpsPackage.HealOpsPackage.json
└───Stats
└──────Template.Stats.ps1
└───TestsAndRepairs
└──────RenameThis.Repairs.ps1
└──────RenameThis.Tests.ps1
```
3. Define the config file.
    3. See [this](https://github.com/larssb/PlasterPlethora/blob/master/HealOpsPackage/content/HealOpsPackageConfig/HealOpsPackageConfig.json) HealOpsPackage config file template.
4. Define the `Template.Stats.ps1` file.
    4. See [this](https://github.com/larssb/PlasterPlethora/blob/master/HealOpsPackage/content/Stats/Stats_Template.ps1) HealOpsPackage stats file template.
5. Define the Tests and Repairs files.
    5. The *.Tests.ps1 file > See [this](https://github.com/larssb/PlasterPlethora/blob/master/HealOpsPackage/content/TestsAndRepairs_Templates/Tests.ps1) template.
    5. The *.Repairs.ps1 file > See [this](https://github.com/larssb/PlasterPlethora/blob/master/HealOpsPackage/content/TestsAndRepairs_Templates/Repairs.ps1) template.

__N.B.__ you could also choose NOT to define the files as templates and then just get at it. Meaning: Programming the *.Tests.ps1, *.Stats.ps1 or *.Repairs.ps1 files for the IT system or component you want HealOps to look at.