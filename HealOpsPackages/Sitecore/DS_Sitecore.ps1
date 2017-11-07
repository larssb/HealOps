<#
    - Script for invoking HealOps on a Sitecore instance runing in Danske Spil
#>
# Test the Octopus Deploy tentacle (Agent)
Invoke-HealOps -TestFilePath $PSScriptRoot\TestsAndRepairs\octopusdeploy.tentacle.Tests.ps1

# Test for enough diskspace
Invoke-HealOps -TestFilePath $PSScriptRoot\TestsAndRepairs\octopusdeploy.tentacle.Tests.ps1
