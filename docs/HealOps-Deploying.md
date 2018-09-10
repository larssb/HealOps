# Deploying HealOps

## Preparation

When deploying HealOps to a node you will need to deploy:

* The specific HealOps package/s needed in order to monitor and repair the IT system or component of interest.
* HealOps itself.

So figure out which HealOps packages you need, if they aren't available, you can develop them yourself. Read more on the [Developing a HealOpsPackage](./HealOpsPackages-GettingStarted.md).

## An actual deploy

* Execute: `Install-HealOps.ps1 -APIKey KEY -FeedName HealOps -HealOpsPackages WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage -JobType WinScTask -PackageManagementURI URI -MetricsSystem OpenTSDB -MetricsSystemIP IP -MetricsSystemPort PORT -Verbose`
        * The above will try to install these four HealOps packages: `WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage`
        * The Tests and Stats files in these packages will be executed via `Windows Scheduled Tasks`.
        * The command will execute with `Verbose` output.
        * The APIKey is the native API key if you are using ProGet as your package management system.

See the below video as an example of deploying HealOps.