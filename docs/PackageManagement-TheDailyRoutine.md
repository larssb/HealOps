# Every day management

## Registering your package management feed

* Open PowerShell
* Register the feed: `Register-PSRepository -Name HealOps -SourceLocation FEED_URI -PublishLocation FEED_URI/ -ScriptSourceLocation FEED_URI -ScriptPublishLocation FEED_URI/ -InstallationPolicy Trusted -PackageManagementProvider NuGet`
        * In the above command, the trailing slash (/) in `FEED_URI` is important.