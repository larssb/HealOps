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
    .PARAMETER metricValue
        The value to record on the metric being writen to OpenTSDB.
    .PARAMETER RepairMetricValue
        With this parameter you specify the metricvalue to report for a repair, relative to the result of Repair-EntityState.
    #>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [Parameter(Mandatory=$true, ParameterSetName="Repair", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("OpenTSDB")]
        [String]$reportBackendSystem,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.")]
        [Parameter(Mandatory=$true, ParameterSetName="Repair", HelpMessage="The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.")]
        [ValidateNotNullOrEmpty()]
        [String]$metric,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The value to record on the metric being writen to OpenTSDB.")]
        [ValidateNotNullOrEmpty()]
        [int]$metricValue,
        [Parameter(Mandatory=$true, ParameterSetName="Repair", HelpMessage="With this parameter you specify the metricvalue to report for a repair, relative to the result of Repair-EntityState.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0,1)]
        [int]$RepairMetricValue
    )

    #############
    # Execution #
    #############
    <#
        - Transform incoming data to send to the report backend
    #>
    # Define tags in JSON
    $tags = @{}
    $tags.Add("node",(get-hostname))
    $tags.Add("environment",$($HealOpsPackageConfig.environment))

    <#
        - Set specific settings in relation to what metric value paraneter that was provided.
    #>
    if ($PSCmdlet.ParameterSetName -eq "Repair") {
        [int]$Value = $RepairMetricValue

        # Component tag
        $tags.Add("component",$metric)

        # Add repair status tag.
        if ($RepairMetricValue -eq 1) {
            $tags.Add("Status","RepairSucceeded")
        } else {
            $tags.Add("Status","RepairFailed")
        }

        # Set the metric name to use for repairs on the component being reported on.
        $metric = ("HealOps.Repair")
    } else {
        [int]$Value = $metricValue
    }

    # Determine the reporting backend system to use & push the report
    switch ($reportBackendSystem) {
        { $_ -eq "OpenTSDB" } {
            Import-Module -name $PSScriptRoot/ReportHelpers/OpenTSDB/OpenTSDB -Force
            $result = write-metricToOpenTSDB -metric $metric -tagPairs $tags -metricValue $Value -verbose
        }
        Default {
            # TODO: Make sure that personnel is alarmed that reporting is not working!
            throw "The reporting backend could not be determined."
        }
    }

    if ($result -eq $false) {
        # TODO: Make sure that personnel is alarmed that reporting is not working!
            ## Who to report to
                ### Driften?
                ### HealOps admins?
    }
}