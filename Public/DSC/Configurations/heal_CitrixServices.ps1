<#
    .SYNOPSIS
        Ensures that Citrix services are running.
#>
Configuration HealCitrixServices
{
    Import-DscResource -Name MSFT_xServiceResource -ModuleName xPSDesiredStateConfiguration

    xService CitrixService
    {
        Name   = 'Spooler'
        Ensure = 'Present'
        State  = 'Running'
    }
}