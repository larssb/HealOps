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
    Submit-EntityStateReport -
    Explanation of what the example does
.PARAMETER reportBackendSystem
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER metric
    The name of the metric, in a format supported by the reporting backend.
.PARAMETER TestData
    A Hashtable or Int32 type object. Containing testdata.
.PARAMETER RepairMetricValue
    With this parameter you specify the TestData to report for a repair, relative to the result of Repair-EntityState().
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory)]
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [ValidateSet("OpenTSDB")]
        [String]$reportBackendSystem,
        [Parameter(Mandatory)]
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [ValidateNotNullOrEmpty()]
        [String]$metric,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $TestData,
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [ValidateSet(0,1)]
        [int]$RepairMetricValue
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Sanity tests
        #>
        if ($PSBoundParameters.ContainsKey('TestData')) {
            # Determine the type of the incoming object to the TestData parameter.
            if (-not $TestData.GetType().Name -eq "Hashtable" -or -not $TestData.GetType().Name -eq "Int32") {
                # Throw
                $testDataType = $TestData.GetType().Name
                throw "The datatype of the TestData parameter is not supported. The datatype is > $testDataType"
            }
        }

        ############################
        # PRIVATE HELPER FUNCTIONS #
        ############################
        <#
            - Reports to a reporting backend
                > Invoke-ReportIt declared here to avoid it being exposed outside Submit-EntityStateReport(). Used to adhere to DRY. So that we can support [Hashtable] and [Int32] case on the TestData param coming
                into the mother function (Submit-EntityStateReport).
        #>
        function Invoke-ReportIt () {
        <#
        .DESCRIPTION
            Private function used to report to a reporting backend.
        .INPUTS
            <none>
        .OUTPUTS
            [Bool] relative to success/failure in regards to reporting to the report backend.
        .NOTES
            <none>
        .EXAMPLE
            $result = Invoke-ReportIt -reportBackendSystem $reportBackendSystem -metric $metric -metricValue $RepairMetricValue -tags $tags
                > Calles Invoke-ReportIt to report to the report backend system specified in the $reportBackendSystem variable. With the data in the metric, metricvalue and tags variables.
        .PARAMETER reportBackendSystem
            Used to specify the software used as the reporting backend. For storing test result metrics.
        .PARAMETER metric
            The name of the metric, in a format supported by the reporting backend.
        .PARAMETER metricValue
            The value to record on the metric being writen to the reporting backend.
        .PARAMETER tags
            The tags to set on the metric. Used to improve querying on the reporting backend. Provided as a Key/Value collection.
        .PARAMETER log4netLoggerDebug
            The log4net debug log object.
        #>

            # Define parameters
            [CmdletBinding(DefaultParameterSetName="Default")]
            [OutputType([Boolean])]
            param(
                [Parameter(Mandatory)]
                [ValidateSet("OpenTSDB")]
                [String]$reportBackendSystem,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [String]$metric,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [int]$metricValue,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [hashtable]$tags,
                [Parameter(Mandatory)]
                $log4netLoggerDebug
            )

            #############
            # Execution #
            #############
            # Debug logging
            Write-Verbose -Message "The metric to report on is > $metric"
            $log4netLoggerDebug.debug("The metric to report on is > $metric")
            Write-Verbose -Message "It's value is > $metricValue"
            $log4netLoggerDebug.debug("It's value is > $metricValue")
            Write-Verbose -Message "The following values are in the tags collection on the metric > $($tags.values)"
            $log4netLoggerDebug.debug("The following values are in the tags collection on the metric > $($tags.values)")

            # Determine the reporting backend system to use & push the report
            switch ($reportBackendSystem) {
                { $_ -eq "OpenTSDB" } {
                    Import-Module -name $PSScriptRoot/ReportHelpers/OpenTSDB/OpenTSDB -Force
                    $result = write-metricToOpenTSDB -metric $metric -tagPairs $tags -metricValue $metricValue -verbose
                }
                Default {
                    throw "The reporting backend could not be determined."
                }
            }

            # Return
            $result
        }

        <#
            - Generates std. tags
                > Declared here to avoid it being exposed outside Submit-EntityStateReport().
        #>
        function Get-StandardTagCollection() {
        <#
        .DESCRIPTION
            Generates and returns standard tags
        .INPUTS
            <none>
        .OUTPUTS
            [HashTable]
        .NOTES
            General notes
        .EXAMPLE
            [Hashtable]$tags = Get-StandardTagCollection
            > Generates and returns standard tags
        .PARAMETER HealOpsPackageConfig
            The content of the config file in the HealOps package.
        #>

            # Define parameters
            [CmdletBinding(DefaultParameterSetName="Default")]
            [OutputType([HashTable])]
            param(
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [PSCustomObject]$HealOpsPackageConfig
            )

            #############
            # Execution #
            #############
            # Define tags in JSON
            $tags = @{}
            $tags.Add("node",(get-hostname))
            $tags.Add("environment",$($HealOpsPackageConfig.environment))

            # Return
            $tags
        }
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "Repair") {
            # Get std. tags
            [Hashtable]$tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig

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

            # Report it
            try {
                $result = Invoke-ReportIt -reportBackendSystem $reportBackendSystem -metric $metric -metricValue $RepairMetricValue -tags $tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
            } catch {
                # TODO: Alarm that state data could be reported
            }
        } else {
            if ($TestData.GetType().Name -eq "Hashtable") {
                # Iterate over each entry in the TestData Hashtable
                $enumerator = $TestData.GetEnumerator()
                foreach ($entry in $enumerator) {
                    # Get std. tags
                    [Hashtable]$tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig

                    # Component tag (Name == Key in the Hashtable)
                    $tags.Add("component",$entry.Name)

                    # Report it
                    try {
                        $result = Invoke-ReportIt -reportBackendSystem $reportBackendSystem -metric $metric -metricValue $entry.Value -tags $tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
                    } catch {
                        # TODO: Alarm that state data could be reported
                    }
                }
            } else {
                # Get std. tags
                [Hashtable]$tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig

                # Report it
                try {
                    $result = Invoke-ReportIt -reportBackendSystem $reportBackendSystem -metric $metric -metricValue $TestData -tags $tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
                } catch {
                    # TODO: Alarm that state data could be reported
                }
            }
        }
    }
    End {}
}