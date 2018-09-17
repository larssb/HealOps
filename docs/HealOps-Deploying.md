# Deploying HealOps

## Pre-requisites

HealOps rely on some backend services and components. These are described on [The components of HealOps](./HealOps-ArchitectureAndInnerWorkings.md#the-components-of-healops). Please refer to that as these needs to be in place before HealOps will be able to show its full potential (AKA work).

### The Install-HealOps script

This script should be published to the nuget feed you are using for HealOps (on your package management system). Read more on this via the link in the "Pre-requisites" section above.

## Preparation

When deploying HealOps to a node you will need to deploy:

* The specific HealOps package/s needed in order to monitor and repair the IT system or component of interest.
        * Therefore, figure out which HealOps packages you need, if they aren't available, you can develop them yourself. Read more on [developing HealOpsPackage's](./HealOpsPackages-GettingStarted.md).
* HealOps itself.
* Register the repository where the feed, with all the relevant packages reside. See [Registering your package management feed](./PackageManagement-TheDailyRoutine.md/#registering-your-package-management-feed)

## An actual deploy

* Download/install the Install-HealOps script: `Install-Script -Name Install-HealOps -Repository HealOps` >> answer `yes` to the "PATH environment Variable change". It will make your life much easier when using the `Install-HealOps` script.
        * The `Install-Script` cmdlet is a part of the `PowerShellGet` module. This module works best with version 5.0+ of PowerShell.
* Execute: `Install-HealOps.ps1 -APIKey KEY -FeedName HealOps -HealOpsPackages WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage -JobType WinScTask -PackageManagementURI URI -MetricsSystem OpenTSDB -MetricsSystemIP "IP" -MetricsSystemPort 4242 -Verbose`
        * The above will try to install these four HealOps packages: `WindowsSystem.HealOpsPackage,Sitecore.HealOpsPackage,MSSQL.HealOpsPackage,IIS.HealOpsPackage`
        * The Tests and Stats files in these packages will be executed via `Windows Scheduled Tasks` because of the `WinScTask` value to the `-JobType` parameter.
        * The command will execute with `Verbose` output.
        * The APIKey is the native API key if you are using ProGet as your package management system.
* If all went well HealOps and the HealOps packages you specified to the `Install-HealOps` function will now have been installed. Now, you need to do some final customizations of the installed HealOps packages and _maybe_ some of the actual scripts inside the HealOps packages. **_its on the to-do list to make it easier to deploy HealOps. In a way that makes it unnecessary to do additional work after a deploy. It will likely be in the line of some pre-deploy steps. Steps that will likely be a part of builing a HealOps package_**.

### Post deploy

* Configure a new dashboard, or graphs on an already existing dashboard, on a metric visualizatio system like `Grafana`. For help on how-to do this with `Grafana` go [here](./Grafana-VisualizingMetrics.md). `Grafana` is just one possible product to use in the metric visualization category. You are free to select another system. As long as it supports pulling metrics from a time-series database like `OpenTSDB`.
        * As you setup graphs you will also be able to verify that metric data is coming/can be collected from the time-series database.
* Setup proper and logical alerts on the created graphs. Alerts are a feature that combines a graph threshold with an automated alert. The treshold is of course relative to what you consider a healthy state of the IT system or component being followed by HealOps. This makes it possible to raise an alert on an unhealthy state, in the case that it was not repaired automatically by HealOps. Such a raised alarm can then be forwarded (via a webhook) to an incident managemet system. E.g. [OpsGenie](https://www.opsgenie.com/). Via the incident management system, the on-call personnel responsible for the system, is automatically contacted along with data on the metric above a configured threshold.
        * This is an optional step but will give you the full potential of HealOps. Namely a fully automatized flow of monitoring, repairing and alerting on an IT system and its components.
        * For a helping hand on how-to configure an alarm on a graph, go [here](Grafana-ConfigurationAndSetup.md#configuring-an-alert).