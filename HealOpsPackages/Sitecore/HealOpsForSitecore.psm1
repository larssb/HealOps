<#
    EXPLAIN_WHAT_IT_DOES
#>
# Define the Ensure property as Enum. A DSC resource requirement.
enum Ensure
{
    # Sitecore website state
    Alive
    NotAlive

    #
}

# Declare and define the DSC resource class
[DscResource()]
class sitecoreWebsite {
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
        $result = & "$PSScriptRoot\Private\siteCoreWebsite.ps1";

        return $result
    }

    <#
        EXPLAIN_WHAT_IT_DOES

        N.B.: This method is equivalent of the Get-TargetResource script function. The implementation should use the keys to find
        appropriate resources. This method returns an instance of this class with the updated key properties.
    #>
    [sitecoreWebsite] Get() {
        return $this
    }

    ###############################
    # DSC RESOURCE HELPER METHODS #
    ###############################

}