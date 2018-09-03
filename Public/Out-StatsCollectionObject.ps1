function Out-StatsCollectionObject() {
<#
.DESCRIPTION
    Outputs a collection, matching the requirements of HealOps when reporting stats on 'x' IT system/component. You will use this function together with the Out-StatsItemObject function. The StatsItem is to be added to the
    StatsCollectionObject you get back from this function.
.INPUTS
    <none>
.OUTPUTS
    [System.Collections.Generic.List`1[StatsItem]] representing a collection to hold StatsItem objects. So a generic collection matching the requirements of
    HealOps.
.NOTES
    Set to output [Void] in order to comply with the PowerShell language. Also if [Void] wasn't used, an error would be thrown when invoking the function.
    As the output type [System.Collections.Generic.List`1[StatsItem]] would not be known by PowerShell, when this function is invocated.
.EXAMPLE
    PS C:\> Out-StatsCollectionObject
    Outputs a collection, matching the requirements of HealOps when reporting stats on 'x' IT system/component.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Void])]
    Param()

    #############
    # Execution #
    #############
    Begin {
        . $PSScriptRoot/../Private/StatsMode/StatsItem.Class.ps1
    }
    Process {
        # Create a strongly typed collection. To hold only StatsItem objects.
        $StatsCollectionObject = [System.Collections.Generic.List`1[StatsItem]]::new()
    }
    End {
        # Return it. The comma in front of the object is to stop PowerShell from unrolling the collection.
        ,$StatsCollectionObject
    }
}