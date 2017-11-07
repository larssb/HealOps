#Requires -
function New-HealOpsPackageRunner() {
<#
.DESCRIPTION
    Generates the main script file to be used as the initiating point of execution when invoking a HealOps package.
        - Takes all the *.Tests.ps1 files in the 'TestsAndRepairs' folder
        - Generates a line per *.Tests.ps1 file in the generated script
        - Prepares for commenting in the generated script
.INPUTS
    Inputs (if any)
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER NAME_OF_THE_PARAMETER_WITHOUT_THE_QUOTES
    Parameter_HelpMessage_text
    Add_a_PARAMETER_per_parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The full path to the TestsAndRepairs folder of the HealOpsPackage to generate a runner script for.")]
        [ValidateNotNullOrEmpty()]
        $PathToTestsAndRepairsFolder
    )

    DynamicParam {
        if($PARAMETER -eq "") {
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute;
            $attributes.Mandatory = $true;
            $attributes.HelpMessage = " PARAMETER_DESCRIPTION ";
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute;

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute];
            $attributeCollection.Add($attributes);
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute);

            # Prepare to return & expose the parameter
            $ParameterName = "PARAMETER_NAME";
            [Type]$ParameterType = "PARAMETER_TYPE";
            $Parameter = New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, $ParameterType, $AttributeCollection);
            if ($psboundparameters.ContainsKey('DefaultValue')) {
                $Parameter.Value = $DefaultValue;
            }
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary;
            $paramDictionary.Add($ParameterName, $Parameter);

            return $paramDictionary;
        }
    }

    #############
    # Execution #
    #############
    Begin {}
    Process {

    }
    End{}
}

Export-ModuleMember -Function ""