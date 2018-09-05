function Out-StatsItemObject() {
<#
.DESCRIPTION
    Returns an object specifically shaped to adhere to the requirements of the StatsMode of HealOps. The object is to be used for reporting on 'x' specific
    IT system/component, matching 'x' IT system/component.
.INPUTS
    <none>
.OUTPUTS
    [StatsItem] an object specifically structured to adhere to the requuirements of using the statsmode of HealOps. The returned StatsItem object is to be used as the
    template for reporting Stats data/values on 'x' specific metric, matching 'x' IT system/component.
.NOTES
    Set to output [Void] in order to comply with the PowerShell language. Also if [Void] wasn't used, an error would be thrown when invoking the function.
    As the output type [StatsItem] would not be known by PowerShell, when this function is invocated.
.EXAMPLE
    PS C:\> Out-StatsItemObject
    The example will return a StatsItem object, structured specifically to adhere to the requirements of reporting stats on an IT system/component via HealOps.
.PARAMETER IncludeStatsOwnerProperty
    Includes a "StatsOwner" property on the returned StatsItem object.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Void])]
    Param(
        [Parameter()]
        [Switch]$IncludeStatsOwnerProperty
    )

    #############
    # Execution #
    #############
    # Return a StatsItem object.
    if ($IncludeStatsOwnerProperty) {
        [StatsItem]::New("",@{},"")
    } else {
        [StatsItem]::New("",@{})
    }
}