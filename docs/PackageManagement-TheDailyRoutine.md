# Every day management

## Registering your package management feed

* Open a PowerShell terminal
* Register the feed: `Register-PSRepository -Name HealOps -SourceLocation FEED_URI -PublishLocation FEED_URI/ -ScriptSourceLocation FEED_URI -ScriptPublishLocation FEED_URI/ -InstallationPolicy Trusted -PackageManagementProvider NuGet`
        * In the above command, the trailing slash (/) in `FEED_URI` is important.

## Publishing packages

* Open a PowerShell terminal.
* Publish a package by executing: `Publish-Module -Path .\FOLDER\HealOpsPackages\Sitecore.HealOpsPackage -NuGetApiKey FEED_KEY -Repository HealOps`
        * Publishes the Sitecore HealOps package to the HealOps repository.
        _See this [video]() for an example_