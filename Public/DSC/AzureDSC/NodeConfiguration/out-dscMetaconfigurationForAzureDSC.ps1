####################
# FUNCTIONS - PREP #
####################
#Requires -Version 5

#####################
# PUBLIC FUNCTIONS - START #
#####################
function out-dscMetaconfigurationForAzureDSC() {
<#
.DESCRIPTION
    Helper function to create the required meta configuration file to apply to nodes that you want
    onboarded to an Azure automation DSC setup.

    - Potential requirements

    - Returns: spits out a meta configuration file.

.PARAMETER azureAutomationRegistrationKey
    The registration key of your Azure Automation account.
.PARAMETER azureAutomationURL
    The URL of your Azure automation account.
.PARAMETER computerToOnboard
    The computer or computers to onboard to Azure automation DSC.
.EXAMPLE
    C:\PS>
    <Description of example>
#>

    # Define parameters
    param(
        [Parameter(Mandatory=$true, ParameterSetName="default", HelpMessage="The registration key of your Azure Automation account.")]
        [ValidateNotNullOrEmpty()]
        $azureAutomationRegistrationKey,
        [Parameter(Mandatory=$true, ParameterSetName="default", HelpMessage="The URL of your Azure automation account.")]
        [ValidateNotNullOrEmpty()]
        $azureAutomationURL,
        [Parameter(Mandatory=$true, ParameterSetName="default", HelpMessage="The computer or computers to onboard to Azure automation DSC.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$computerToOnboard
    )

    ####
    # PREP
    ####
    # Import the private DscMetaConfigs script. The DSConfiguration that creates the metaconfiguration
    . $PSScriptRoot\..\..\..\Private\DSC\AzureDSC\NodeConfiguration\DscMetaConfigs.ps1;

    ####
    # Execution
    ####
    # Create the metaconfigurations
    $Params = @{
        RegistrationUrl = $azureAutomationURL;
        RegistrationKey = $azureAutomationRegistrationKey;
        ComputerName = @($computerToOnboard);
        #NodeConfigurationName = 'SimpleConfig.webserver';
        NodeConfigurationName = 'healOps.AzureAutomationDSC';
        RefreshFrequencyMins = 30;
        ConfigurationModeFrequencyMins = 15;
        RebootNodeIfNeeded = $False;
        AllowModuleOverwrite = $False;
        ConfigurationMode = 'ApplyAndMonitor';
        ActionAfterReboot = 'ContinueConfiguration';
        ReportOnly = $False;  # Set to $True to have machines only report to a DSC but not pull from it
    }

    # Generate the mof
    DscMetaConfigs @params;

    # .
}
###################
# PUBLIC FUNCTIONS - END #
####################