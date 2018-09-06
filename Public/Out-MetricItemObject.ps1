function Out-MetricItemObject() {
<#
.DESCRIPTION
    Returns an object specifically shaped to adhere to the requirements of the StatsMode of HealOps. The object is to be used for reporting on 'x' specific
    IT system/component, matching 'x' IT system/component.
.INPUTS
    <none>
.OUTPUTS
    [MetricItem] an object specifically structured to adhere to the requuirements of using the statsmode of HealOps. The returned MetricItem object is to be used as the
    template for reporting Stats data/values on 'x' specific metric, matching 'x' IT system/component.
.NOTES
    Set to output [Void] in order to comply with the PowerShell language. Also if [Void] wasn't used, an error would be thrown when invoking the function.
    As the output type [MetricItem] would not be known by PowerShell, when this function is invocated.
.EXAMPLE
    PS C:\> Out-MetricItemObject
    The example will return a MetricItem object, structured specifically to adhere to the requirements of reporting stats on an IT system/component via HealOps.
.PARAMETER IncludeStatsOwnerProperty
    Includes a "StatsOwner" property on the returned MetricItem object.
.PARAMETER SingleValue
    Returns a MetricItem object with a "Metric" [String] property and a [Int] property, used when you want to store a single value to one metric on the Time-series database backend.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Void])]
    Param(
        [Parameter(ParameterSetName="StatsOwner")]
        [Switch]$IncludeStatsOwnerProperty,
        [Parameter(ParameterSetName="SingleVal")]
        [Switch]$SingleValue
    )

    #############
    # Execution #
    #############
    # Return a MetricItem object.
    if ($IncludeStatsOwnerProperty) {
        [MetricItem]::New("",@{},"")
    } elseif ($SingleValue) {
        [MetricItem]::New("",0)
    } else {
        [MetricItem]::New("",@{})
    }
}