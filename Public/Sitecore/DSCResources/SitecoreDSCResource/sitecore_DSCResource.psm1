<#
    EXPLAIN_WHAT_IT_DOES
#>
# Define the Ensure property as Enum. A DSC resource requirement.
enum Ensure
{
    Answering
    NotAnswering
}

#

# Declare and define the DSC resource class
[DscResource()]
class sitecore_DSCResource {
    ##############
    # PROPERTIES #
    ##############
    # The values of all properties marked as keys must combine to uniquely identify a resource instance within a configuration.
    [DscProperty(Key)]
    [string]$dsSitecoreInstance

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    #############################
    # MAIN DSC RESOURCE METHODS #
    #############################
    <#
        EXPLAIN_WHAT_IT_DOES

        N.B.: This method is equivalent of the Set-TargetResource script function. It sets the resource to the desired state.
    #>
    [Void] Set() {

    }

    <#
        EXPLAIN_WHAT_IT_DOES

        N.B.: This method is equivalent of the Test-TargetResource script function. It should return True or False, showing whether
        the resource is in a desired state.
    #>
    [bool] Test() {
        # Create mock object for comparison
        $failMockComparison = @("Failed");

        # Run the tests with OVF
        $ovfOutput = Invoke-OperationValidation -testFilePath $PSScriptRoot\Diagnostics\Comprehensive\sitecore.Tests.ps1;

        # Compare the two. The ovfOutput object should not hold any "FAILED" tests. That is what is being looked for.
        $comparisonResult = Compare-Object -DifferenceObject $ovfOutput.Result -ReferenceObject $failMockComparison -IncludeEqual -ExcludeDifferent;

        # Evaluate the comparison and return the result
        if ($null -eq $comparisonResult) {
            return $true;
        } else {
            return $false;
        }
    }

    <#
        EXPLAIN_WHAT_IT_DOES

        N.B.: This method is equivalent of the Get-TargetResource script function. The implementation should use the keys to find
        appropriate resources. This method returns an instance of this class with the updated key properties.
    #>
    [sitecore_DSCResource] Get() {
        return $this
    }

    ###############################
    # DSC RESOURCE HELPER METHODS #
    ###############################

}