<#
    .SYNOPSIS
        Ensures that Citrix services are running.
#>
Configuration StartCitrixServices
{
    Import-DscResource -Name MSFT_xServiceResource -ModuleName xPSDesiredStateConfiguration

    xService CitrixService
    {
        Name   = 'Spooler'
        Ensure = 'Present'
        State  = 'Running'
    }
}