# Deploying HealOps

## Pre-requisites

HealOps rely on some backend services and components. These are described on [The components of HealOps](./HealOps-ArchitectureAndInnerWorkings.md#the-components-of-healops). Please refer to that as these needs to be in place before HealOps will be able to show its full potential (AKA work).

### The Install-HealOps script

This script should be published to the nuget feed you are using for HealOps (on your package management system). Read more on the link in the "Pre-requisites" section on this page.

## Preparation

When deploying HealOps to a node you will need to deploy:

* The specific HealOps package/s needed in order to monitor and repair the IT system or component of interest.
* HealOps itself.

So figure out which HealOps packages you need, if they aren't available, you can develop them yourself. Read more on [developing HealOpsPackages](./HealOpsPackages-GettingStarted.md).

* Register the repository where the feed, with all the relevant packages reside. See [Registering your package management feed](./PackageManagement-TheDailyRoutine.md/#registering-your-package-management-feed)

## An actual deploy

* Download/install the Install-HealOps script: `Install-Script -Name Install-HealOps -Repository HealOps` >> answer `yes` to the "PATH environment Variable change". It will make your life much easier when using the `Install-HealOps` script.
* Execute: `Install-HealOps.ps1 -APIKey KEY -FeedName HealOps -HealOpsPackages WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage -JobType WinScTask -PackageManagementURI URI -MetricsSystem OpenTSDB -MetricsSystemIP IP -MetricsSystemPort PORT -Verbose`
        * The above will try to install these four HealOps packages: `WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage`
        * The Tests and Stats files in these packages will be executed via `Windows Scheduled Tasks`.
        * The command will execute with `Verbose` output.
        * The APIKey is the native API key if you are using ProGet as your package management system.
* If all went well HealOps and the HealOps packages you specified to the `Install-HealOps` function will now have been installed. Now, you need to do some final customizations of the installed HealOps packages and _maybe_ some of the actual scripts inside the HealOps packages. **_its on the to-do list to make it easier to deploy HealOps. In a way that makes it unnecessary to do additional work after a deploy. It will likely be in the line of some pre-deploy steps. Steps that will likely be a part of builing a HealOps package_**.

See the below video as an example of deploying HealOps.