<<<<<<< HEAD:Public/DSC/Configurations/it_services/Citrix/heal_CitrixServicesProvisioningRole.ps1
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
=======
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
>>>>>>> 6bff47c62854fcd4620ce3f5e7d29cafae108b52:Public/DSC/Configurations/it_services/Citrix/heal_CitrixServicesProvisioningRole.ps1
}