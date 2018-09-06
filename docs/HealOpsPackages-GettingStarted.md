# Developing a HealOpsPackage

__The easy way to get going__

1. If `Plaster` isn't already installed on your box then install it: `Install-Module -Name Plaster -Repository PSGallery`
2. Execute `Invoke-Plaster - _see the below video, showing the effects of running Invoke-Plaster to create a HealOpsPackage_. It uses the template found in [PlasterPlethora][https://github.com/larssb/PlasterPlethora]{:.no-mark-external}.



__The long way__

If you for some reason (which is hard to fathom) do not want to use the Plaster PowerShell module you need to follow the below guide to get going.

1. Create the following folder structure.
```txt
THE_NAME_OF_THE_HealOpsPackage > It will be the root folder
└───Config > Contains the configuration file for the HealOpsPackage.
└───Stats > Contains the *.Stats.ps1 files, used to report metric stats data on an IT System or component.
└───TestsAndRepairs > Contains the *.Tests.ps1 (Pester test files) and the *.Repairs.ps1 files.
└───*.HealOpsPackage.psd1 > The HealOpsPackage PowerShell module manifest file.
└───*.HealOpsPackage.ReadMe.md > A ReadMe markdown file explaining what the HealOps package contains and do.
```
2.