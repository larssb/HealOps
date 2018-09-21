function Submit-EntityStateReport() {
<#
.DESCRIPTION
    Used to report stats, repair and test data to the HealOps backend.
.INPUTS
    $Data.
    [String]Metric. The metric to report on in the time shift database backend system.
    [int]RepairMetricValue. Either 1 or 0 ($true or $false), relative to the result of repairing a failed state of an IT system/component.
.OUTPUTS
    <none>
.NOTES
    <none>
.EXAMPLE
    Submit-EntityStateReport -Config $HealOpsConfig -Metric $Metric -MetricsSystem "OpenTSDB" -Data $Data
    Requests Submit-EntityStateReport to send data for storage to the HealOps backend on a specific metric.
.EXAMPLE
    Submit-EntityStateReport -Metric $Metric -MetricsSystem "OpenTSDB" -RepairMetricValue 1
    Requests Submit-EntityStateReport to send the repair result value (in this case 1 which equals $true) of a specific metric, for storage on the HealOps backend.
.PARAMETER Config
    The HealOps config file.
.PARAMETER Data
    The data to report to the HealOps backend. It can be a Hashtable, StatsCollection[StatsItem] or a Int32 type object.
.PARAMETER Metric
    The name of the metric, in a format supported by the reporting backend.
.PARAMETER MetricsSystem
    The system used to store metrics.
.PARAMETER RepairMetricValue
    With this parameter you specify the data to report for a repair, relative to the result of Repair-EntityState().
.PARAMETER StatsOwner
    Holds the value of an owning node of 'x' stat.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Void])]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config,
        [Parameter(Mandatory, ParameterSetName="StatsAndTest")]
        [ValidateNotNullOrEmpty()]
        $Data,
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [Parameter(Mandatory, ParameterSetName="StatsAndTest")]
        [ValidateNotNullOrEmpty()]
        [String]$Metric,
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [Parameter(Mandatory, ParameterSetName="StatsAndTest")]
        [ValidateSet("OpenTSDB")]
        [String]$MetricsSystem,
        [Parameter(Mandatory, ParameterSetName="Repair")]
        [ValidateSet(0,1)]
        [int]$RepairMetricValue,
        [Parameter()]
        [Parameter(ParameterSetName="StatsAndTest")]
        [ValidateNotNullOrEmpty()]
        [String]$StatsOwner
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Sanity tests
        #>
        if ($PSBoundParameters.ContainsKey('Data')) {
            [Array]$ArrayOfAcceptedDataTypes = "Hashtable", "Int32"
            # Determine the type of the incoming object to the Data parameter.
            if (-not $Data.GetType().Name -in $ArrayOfAcceptedDataTypes -or -not $Data.GetType().FullName -match "StatsItem") {
                # Throw
                $TestDataType = $Data.GetType().FullName
                throw "The datatype of the Data parameter is not supported. The datatype is > $TestDataType"
            }
        }

        <#
            - Variables used througout the function.
        #>
        [String]$InvokeReportItException = "Invoke-ReportIt | Failed with {0}."
        ############################
        # PRIVATE HELPER FUNCTIONS #
        ############################
        <#
            - Reports to a reporting backend
                > Invoke-ReportIt declared here to avoid it being exposed outside Submit-EntityStateReport(). Used to adhere to DRY. So that we can support [Hashtable] and [Int32] case on the Data param coming
                into the mother function (Submit-EntityStateReport).
        #>
        function Invoke-ReportIt () {
        <#
        .DESCRIPTION
            Private inline function used to report to a reporting backend.
        .INPUTS
            <none>
        .OUTPUTS
            [Bool] relative to success/failure in regards to reporting to the report backend.
        .NOTES
            <none>
        .EXAMPLE
            $Result = Invoke-ReportIt -MetricsSystem $MetricsSystem -metric $metric -metricValue $RepairMetricValue -tags $tags
                > Calles Invoke-ReportIt to report to the report backend system specified in the $MetricsSystem variable. With the data in the metric, metricvalue and tags variables.
        .PARAMETER Config
            The HealOps config file.
        .PARAMETER MetricsSystem
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
                [ValidateNotNullOrEmpty()]
                [PSCustomObject]$Config,
                [Parameter(Mandatory)]
                [ValidateSet("OpenTSDB")]
                [String]$MetricsSystem,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [String]$Metric,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [int]$MetricValue,
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [HashTable]$tags,
                [Parameter(Mandatory)]
                $log4netLoggerDebug
            )

            #############
            # Execution #
            #############
            # Debug logging
            Write-Verbose -Message "The Metric to report on is > $Metric"
            $log4netLoggerDebug.debug("The Metric to report on is > $Metric")
            Write-Verbose -Message "The value of the Metric is > $MetricValue"
            $log4netLoggerDebug.debug("The value the Metric is > $MetricValue")
            Write-Verbose -Message "The following values are in the tags collection on the Metric > $($tags.values)"
            $log4netLoggerDebug.debug("The following values are in the tags collection on the Metric > $($tags.values)")

            # Determine the reporting backend system to use & push the report
            switch ($MetricsSystem) {
                { $_ -eq "OpenTSDB" } {
                    Import-Module -name $PSScriptRoot/OpenTSDB/OpenTSDB
                    $Result = Write-MetricToOpenTSDB -Config $Config -Metric $Metric -TagPairs $tags -MetricValue $MetricValue -Verbose
                }
                Default {
                    throw "The reporting backend could not be determined."
                }
            }

            # Return
            $Result
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
            [Hashtable]$tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig
            > Generates and returns standard tags.
        .PARAMETER HealOpsPackageConfig
            A HealOpsPackage config.
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
            Begin {
                # Variables used throughout
                [String]$Environment = $HealOpsPackageConfig.environment

                # Sanity tests
                if($null -eq $Environment -or $Environment.Length -lt 1) {
                    [String]$EnvironmentExceptionMessage = "The value for the 'Environment' tag is not defined. Cannot continue. It is > $Environment. Has it been configured in the config file for the HealOpsPackage?"
                    $log4netlogger.error($EnvironmentExceptionMessage)
                    throw "$EnvironmentExceptionMessage"
                }
            }
            Process {
                # Define tags in JSON
                $tags = @{}
                $tags.Add("node",(get-hostname))
                $tags.Add("environment",$($HealOpsPackageConfig.environment))
            }
            End {
                # Return
                $tags
            }
        }
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq "Repair") {
            # Get Std. tags
            try {
                [Hashtable]$tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig -ErrorAction Stop
            } catch {
                throw $_
            }

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
                $Result = Invoke-ReportIt -Config $Config -MetricsSystem $MetricsSystem -metric $Metric -metricValue $RepairMetricValue -tags $tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
            } catch {
                $log4netlogger.error($([String]::Format($InvokeReportItException, $_)))
            }
        } else {
            if ($Data.GetType().Name -ne "Int32") {
                # Get Std. tags
                try {
                    [Hashtable]$Tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig -ErrorAction Stop
                } catch {
                    throw $_
                }

                # Add the StatsOwner property as a tag, if it's defined.
                if ($PSBoundParameters.ContainsKey('StatsOwner')) {
                    $Tags.Add("StatsOwner",$StatsOwner)
                }

                # Iterate over entries in $Data, not matching the key == "Value" and add the item as a tag on the metric.
                $enumerator = $Data.GetEnumerator()
                foreach ($item in $enumerator) {
                    if (-not ($item.key -eq "Value")) {
                        $Tags.Add($item.key,$item.value)
                    }
                }

                # Report it
                try {
                    $Result = Invoke-ReportIt -Config $Config -MetricsSystem $MetricsSystem -Metric $Metric -MetricValue $Data['Value'] -tags $Tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
                } catch {
                    $log4netlogger.error($([String]::Format($InvokeReportItException, $_)))
                }
            } else {
                # Get Std. tags
                try {
                    [Hashtable]$Tags = Get-StandardTagCollection -HealOpsPackageConfig $HealOpsPackageConfig -ErrorAction Stop
                } catch {
                    throw $_
                }

                # Report it
                try {
                    $Result = Invoke-ReportIt -Config $Config -MetricsSystem $MetricsSystem -Metric $Metric -MetricValue $Data -tags $Tags -log4netLoggerDebug $log4netLoggerDebug -ErrorAction Stop
                } catch {
                    $log4netlogger.error($([String]::Format($InvokeReportItException, $_)))
                }
            }
        }
    }
    End {
        # Return
        $Result
    }
}