function write-metricToOpenTSDB() {
    <#
    .DESCRIPTION
        Wraps a HTTP Push request to an OpenTSDB endpoint. Used to record a metric measured on "X" IT service/Entity
    .INPUTS
        <none>
    .OUTPUTS
        [Boolean]
    .NOTES
        General notes
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .PARAMETER metric
        The metric value, in a format supported by OpenTSDB, of the IT service/Entity to log data for, into OpenTSDB.
    .PARAMETER tagPairs
        The tags to set on the metric. Used to improve querying OpenTSDB. Provided as a Key/Value collection (comparable to pairs of "P").
    .PARAMETER metricValue
        The value to record on the metric being writen to OpenTSDB.
    #>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
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
    # Test that the config file is there
    $configFilePath = "$PSScriptRoot/../Artefacts/openTSDBConfig.json"
    if(Test-Path $configFilePath) {
        # Get config info
        $OpenTSDBconfig = Get-Content -Path $configFilePath -Encoding UTF8 | ConvertFrom-Json
    } else {
        throw "The config file for openTSDB settings does not exist. Fix and try again."
    }

    # Validate input and transfrom to JSON
    # TODO: validate metric input > should conform to "sss.sss.sss.sss.sss"
    $metricHolder = @{}
    $metricHolder.metric = $metric
    $metricHolder.tags = $tagPairs
    $metricHolder.timestamp = (get-date -UFormat %s) -replace ",.+",""; # Unix/POSIX Epoch timestamp. Conforming to the OpenTSDB std.
    $metricHolder.value = $metricValue
    $metricInJSON = ConvertTo-Json -InputObject $metricHolder -Depth 3

    # POST the metric to OpenTSDB
    try {
        $openTSDBendpoint = $OpenTSDBconfig.endpointIP
        $openTSDBport = $OpenTSDBconfig.port
        $result = Invoke-WebRequest -Uri http://$openTSDBendpoint":"$openTSDBport/api/put -Method post -ContentType "application/json" -body $metricInJSON -UseBasicParsing
    } catch {
        throw "HTTP POST to OpenTSDB on $openTSDBendpoint failed with: $_"
    }

    # Check the result of the POST to OpenTSDB
    # TODO: Maybe this changes in OpenTSDB v2.3 <-- where it returns HTTP204
    if ($result.status -eq 200) {
        $true

        # TODO: Log info
    } else {
        $false

        # TODO: Log info
    }
}