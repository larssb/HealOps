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

        # TODO: Look further into the request data... e.g. I got this error:
        <#
            2017-11-09 10:07:44,209 ERROR [OpenTSDB I/O Worker #3] RpcHandler: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] Received an unsupported chunked request: DefaultHttpRequest(chunked: true)
POST /api/put HTTP/1.1
User-Agent: Mozilla/5.0 (Windows NT; Windows NT 6.3; da-DK) WindowsPowerShell/5.1.14409.1005
Content-Type: application/json
Host: 192.168.49.111:4242
Content-Length: 211
Expect: 100-continue
2017-11-09 10:07:44,210 WARN  [OpenTSDB I/O Worker #3] HttpQuery: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] Bad Request on /api/put: Chunked request not supported.
2017-11-09 10:07:44,213 INFO  [OpenTSDB I/O Worker #3] HttpQuery: [id: 0x9344fdcb, /192.168.49.22:51840 => /172.17.0.2:4242] HTTP /api/put done in 4ms
        #>
    }
}