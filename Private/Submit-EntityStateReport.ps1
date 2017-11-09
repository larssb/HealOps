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
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The value to record on the metric being writen to OpenTSDB.")]
        [ValidateNotNullOrEmpty()]
        [int]$metricValue
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

    # Determine the reporting backend system to use & push the report
    switch ($reportBackendSystem) {
        { $_ -eq "OpenTSDB" } {
            Import-Module -name $PSScriptRoot/ReportHelpers/OpenTSDB/OpenTSDB -Force
            $result = write-metricToOpenTSDB -metric $metric -tagPairs $tags -metricValue $metricValue -verbose
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