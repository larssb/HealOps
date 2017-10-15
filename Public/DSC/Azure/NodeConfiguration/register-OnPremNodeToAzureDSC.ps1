####################
# FUNCTIONS - PREP #
####################
#Requires -Version 5
#Requires -Modules PSDesiredStateConfiguration

#####################
# PUBLIC FUNCTIONS - START #
#####################
function register-OnPremNodeToAzureDSC() {
<#
.DESCRIPTION
    Wrapper function to Set-DscLocalConfigurationManager. Configures the local configuration manager on the specified computers with the info
    in the metaconfiguration file.

    - Potential requirements

    - Returns

.PARAMETER " Some parameter "
    "SOME DESCRIPTION OF SAID PARAMETER "
.EXAMPLE
    C:\PS>
    <Description of example>
#>

    # Define parameters
    param(
        [Parameter(Mandatory=$true, ParameterSetName="default", HelpMessage="The name of the computer to apply a DSC Metaconfiguration on.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$computername,
        [Parameter(Mandatory=$true, ParameterSetName="", HelpMessage="The path to the DSC metaconfiguration to apply.")]
        [ValidateNotNullOrEmpty()]
        [string]$path
    )

    ####
    # Execution
    ####
    # Test the path specified
    if (Test-Path -Path $path) {
        Set-DscLocalConfigurationManager -Path $path -ComputerName $computername;
    } else {
        throw "- The path specified could not be verified.";
    }
}

###################
# PUBLIC FUNCTIONS - END #
####################