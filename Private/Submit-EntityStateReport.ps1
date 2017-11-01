function Submit-EntityStateReport() {
<#
.DESCRIPTION
    Long description
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER reportBackendSystem
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER metric
    The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.
.PARAMETER tagPairs
    The tags to set on the metric. Used to improve querying OpenTSDB. Provided as a Key/Value collection.
.PARAMETER metricValue
    The value to record on the metric being writen to OpenTSDB.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("OpenTSDB")]
        [string]$reportBackendSystem,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.")]
        [ValidateNotNullOrEmpty()]
        [String]$metric,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The tags to set on the metric. Used to improve querying OpenTSDB. Provided as a Key/Value collection.")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$tagPairs,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The value to record on the metric being writen to OpenTSDB.")]
        [ValidateNotNullOrEmpty()]
        [int]$metricValue
    )

    #############
    # Execution #
    #############
    # Determine the reporting backend system to use
    switch ($reportBackendSystem) {
        { $_ -eq "OpenTSDB" } {
            Import-Module -name $PSScriptRoot/ReportHelpers/OpenTSDB/OpenTSDB
            $reportExpression = "write-metricToOpenTSDB -metric $metric -tagPairs $tagPairs -metricValue $metricValue"
        }
        Default {
            # TODO: Make sure that personnel is alarmed that reporting is not working!
            throw "The reporting backend could not be determined."
        }
    }

    # Push the report to the reporting backend
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
    $reportExpressionResult = Invoke-Expression -Command $reportExpression

    if ($reportExpressionResult -eq $false) {
        # TODO: Make sure that personnel is alarmed that reporting is not working!
            ## Who to report to
                ### Driften?
                ### HealOps admins?
    }
}


