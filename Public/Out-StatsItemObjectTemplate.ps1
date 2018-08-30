function Out-StatsItemObjectTemplate() {
<#
.DESCRIPTION
    Returns an object specifically shaped to adhere to the requirements of the StatsMode of HealOps. The object is to be used for reporting on 'x' specific
    IT system/component, matching 'x' IT system/component.
.INPUTS
    <none>
.OUTPUTS
    [StatsItem]An object specifically structured to adhere to the requuirements of using the statsmode of HealOps. The returned StatsItem object is to be used as the
    template for reporting Stats data/values on 'x' specific metric, matching 'x' IT system/component.
.NOTES
    <none>
.EXAMPLE
    PS C:\> Out-StatsItemObjectTemplate
    The example will return a StatsItem object, structured specifically to adhere to the requirements of reporting stats on an IT system/component via HealOps.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Void])]
    Param()

    #############
    # Execution #
    #############
    Begin {
        # Import and declare a StatsItem template object
        [StatsItem]$StatsItem = . .$PSScriptRoot/../Private/StatsMode/StatsItem.Class.ps1
    }
    Process {}
    End {
        # Return
        [StatsItem]$StatsItem
    }
}