function Write-MetricToOpenTSDB() {
<#
.DESCRIPTION
    Wraps a HTTP Push request to an OpenTSDB endpoint. Used to record a metric measured on "X" IT system or component.
.INPUTS
    <none>
.OUTPUTS
    [Boolean]
.NOTES
    <none>
.EXAMPLE
    PS C:\> Write-MetricToOpenTSDB -Config $HealOpsConfig -
    Executes Write-MetricToOpenTSDB which will store a metric on a OpenTSDB instance.
.PARAMETER Config
    The HealOps config file.
.PARAMETER Metric
    The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.
.PARAMETER TagPairs
    The tags to set on the metric. Used to improve querying OpenTSDB. Provided as a Key/Value collection (comparable to pairs of "P").
.PARAMETER MetricValue
    The value to record on the metric being writen to OpenTSDB.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Metric,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]$MetricValue,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$TagPairs
    )

    #############
    # Execution #
    #############
    # Validate input and transform to JSON
    $metricHolder = @{}
    $metricHolder.metric = $metric
    $metricHolder.tags = $tagPairs
    $metricHolder.timestamp = (get-date ((get-date).touniversaltime()) -UFormat %s) -replace ",.+","" -replace "\..+","" # Unix/POSIX Epoch timestamp. Conforming to the OpenTSDB Std.
    $metricHolder.value = $metricValue
    try {
        $metricInJSON = ConvertTo-Json -InputObject $metricHolder -Depth 3 -ErrorAction Stop
    } catch {
        $log4netLogger.error("ConvertTo-JSON failed inside Write-MetricToOpenTSDB. It failed with > $_.")
    }

    # POST the metric to OpenTSDB
    try {
        $OpenTSDBendpoint = $Config.Metrics.IP
        $OpenTSDBport = $Config.Metrics.Port
        $Result = Invoke-WebRequest -Uri http://$OpenTSDBendpoint":"$OpenTSDBport/api/put -Method post -ContentType "application/json" -body $metricInJSON -UseBasicParsing
        Write-Verbose -Message "Payload to sent to OpenTSDB is: $metricInJSON"
    } catch {
        throw "HTTP POST to OpenTSDB on $openTSDBendpoint failed with: $_"
    }

    # Check the result of the POST to OpenTSDB. HTTP204 is what OpenTSDB returns. Which per the HTTP Std. means == "The server successfully processed the request and is not returning any content.".
    if ($Result.StatusCode -eq 204) {
        $true
    } else {
        $false
    }
}