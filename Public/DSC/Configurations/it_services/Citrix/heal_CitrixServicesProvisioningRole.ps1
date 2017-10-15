<#
    .SYNOPSIS
        Ensures that Citrix services are running.
#>
Configuration heal_CitrixServicesProvisioningRole
{
    Import-DscResource -ModuleName xPSDesiredStateConfiguration, xPowerShellExecutionPolicy

    xPowerShellExecutionPolicy ExecutionPolicy
    {
        ExecutionPolicy = "Bypass"
    }

    xService citrixService_CdfSvc
    {
        Name   = 'CdfSvc'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }

    xService citrixService_BNPXE
    {
        Name   = 'BNPXE'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }

    xService citrixService_soapserver
    {
        Name   = 'soapserver'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }

    xService citrixService_StreamService
    {
        Name   = 'StreamService'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }

    xService citrixService_BNTFTP
    {
        Name   = 'BNTFTP'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }

    xService citrixService_PVSTSB
    {
        Name   = 'PVSTSB'
        Ensure = 'Present'
        State  = 'Running'
        DependsOn = "[xPowerShellExecutionPolicy]ExecutionPolicy"
    }
}