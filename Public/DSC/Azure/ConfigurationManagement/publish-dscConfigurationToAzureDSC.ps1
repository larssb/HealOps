####################
# FUNCTIONS - PREP #
####################
#Requires -Version 5

<#
    - PSEUDO
    1. use push and request files under private\dsc\azuredsc\configurationManagement
#>

#####################
# PUBLIC FUNCTIONS - START #
#####################
function publish-dscConfigurationToAzureDSC() {
<#
.DESCRIPTION
    Long description
.INPUTS
    Inputs (if any)
.OUTPUTS
    Outputs (if any)
.NOTES
     General notes
.EXAMPLE
     PS C:\> <example usage>
     Explanation of what the example does
.PARAMETER "NAME OF THE PARAMETER WITHOUT THE QUOTES"
     Parameter HelpMessage text
     Add a .PARAMETER per parameter
#>

    # Define parameters
    param(
        [Parameter(Mandatory=$true, ParameterSetName=" NAME ", HelpMessage=" MESSAGE ")]
        [ValidateNotNullOrEmpty()]
        $NAMEOFPARAMETER
    )

    ####
    # Execution
    ####
}
###################
# PUBLIC FUNCTIONS - END #
####################