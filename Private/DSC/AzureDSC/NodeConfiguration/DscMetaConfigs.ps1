<<<<<<< HEAD
# The DSC configuration that will generate metaconfigurations for registrering a node to a pull server
[DscLocalConfigurationManager()]
Configuration DscMetaConfigs
{

    param
    (
        [Parameter(Mandatory = $True)]
        [String]$RegistrationUrl,

        [Parameter(Mandatory = $True)]
        [String]$RegistrationKey,

        [Parameter(Mandatory = $True)]
        [String[]]$ComputerName,

        [Parameter(Mandatory = $True)]
        [Int]$RefreshFrequencyMins = 30,

        [Parameter(Mandatory = $True)]
        [Int]$ConfigurationModeFrequencyMins = 15,

        [Parameter(Mandatory = $True)]
        [String]$ConfigurationMode = "ApplyAndMonitor",

        [Parameter(Mandatory = $True)]
        [String]$NodeConfigurationName,

        [Parameter(Mandatory = $True)]
        [Boolean]$RebootNodeIfNeeded = $False,

        [Parameter(Mandatory = $True)]
        [String]$ActionAfterReboot = "ContinueConfiguration",

        [Parameter(Mandatory = $True)]
        [Boolean]$AllowModuleOverwrite = $False,

        [Parameter(Mandatory = $True)]
        [Boolean]$ReportOnly
    )

    if ($NodeConfigurationName -eq $false -or $NodeConfigurationName -eq "") {
        $ConfigurationNames = $null;
    } else {
        $ConfigurationNames = @($NodeConfigurationName);
    }

    if ($ReportOnly) {
        $RefreshMode = "PUSH";
    } else {
        $RefreshMode = "PULL";
    }

    Node $ComputerName
    {
        Settings {
            RefreshFrequencyMins           = $RefreshFrequencyMins
            RefreshMode                    = $RefreshMode
            ConfigurationMode              = $ConfigurationMode
            AllowModuleOverwrite           = $AllowModuleOverwrite
            RebootNodeIfNeeded             = $RebootNodeIfNeeded
            ActionAfterReboot              = $ActionAfterReboot
            ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
        }

        if ($ReportOnly -eq $false) {
            ConfigurationRepositoryWeb AzureAutomationDSC {
                ServerUrl          = $RegistrationUrl
                RegistrationKey    = $RegistrationKey
                ConfigurationNames = $ConfigurationNames
            }

            ResourceRepositoryWeb AzureAutomationDSC {
                ServerUrl       = $RegistrationUrl
                RegistrationKey = $RegistrationKey
            }
        }

        ReportServerWeb AzureAutomationDSC {
            ServerUrl       = $RegistrationUrl
            RegistrationKey = $RegistrationKey
        }
    }
=======
# The DSC configuration that will generate metaconfigurations for registrering a node to a pull server
[DscLocalConfigurationManager()]
Configuration DscMetaConfigs
{

    param
    (
        [Parameter(Mandatory = $True)]
        [String]$RegistrationUrl,

        [Parameter(Mandatory = $True)]
        [String]$RegistrationKey,

        [Parameter(Mandatory = $True)]
        [String[]]$ComputerName,

        [Parameter(Mandatory = $True)]
        [Int]$RefreshFrequencyMins = 30,

        [Parameter(Mandatory = $True)]
        [Int]$ConfigurationModeFrequencyMins = 15,

        [Parameter(Mandatory = $True)]
        [String]$ConfigurationMode = "ApplyAndMonitor",

        [Parameter(Mandatory = $True)]
        [String]$NodeConfigurationName,

        [Parameter(Mandatory = $True)]
        [Boolean]$RebootNodeIfNeeded = $False,

        [Parameter(Mandatory = $True)]
        [String]$ActionAfterReboot = "ContinueConfiguration",

        [Parameter(Mandatory = $True)]
        [Boolean]$AllowModuleOverwrite = $False,

        [Parameter(Mandatory = $True)]
        [Boolean]$ReportOnly
    )

    if ($NodeConfigurationName -eq $false -or $NodeConfigurationName -eq "") {
        $ConfigurationNames = $null;
    } else {
        $ConfigurationNames = @($NodeConfigurationName);
    }

    if ($ReportOnly) {
        $RefreshMode = "PUSH";
    } else {
        $RefreshMode = "PULL";
    }

    Node $ComputerName
    {
        Settings {
            RefreshFrequencyMins           = $RefreshFrequencyMins
            RefreshMode                    = $RefreshMode
            ConfigurationMode              = $ConfigurationMode
            AllowModuleOverwrite           = $AllowModuleOverwrite
            RebootNodeIfNeeded             = $RebootNodeIfNeeded
            ActionAfterReboot              = $ActionAfterReboot
            ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
        }

        if ($ReportOnly -eq $false) {
            ConfigurationRepositoryWeb AzureAutomationDSC {
                ServerUrl          = $RegistrationUrl
                RegistrationKey    = $RegistrationKey
                ConfigurationNames = $ConfigurationNames
            }

            ResourceRepositoryWeb AzureAutomationDSC {
                ServerUrl       = $RegistrationUrl
                RegistrationKey = $RegistrationKey
            }
        }

        ReportServerWeb AzureAutomationDSC {
            ServerUrl       = $RegistrationUrl
            RegistrationKey = $RegistrationKey
        }
    }
>>>>>>> 6bff47c62854fcd4620ce3f5e7d29cafae108b52
}