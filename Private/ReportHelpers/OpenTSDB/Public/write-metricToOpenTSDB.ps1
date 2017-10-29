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
.PARAMETER entityName
    The name of the IT service/Entity that a metric is being recorded for.
.PARAMETER entityComponent
    The name of the component of IT service/Entity that a metric is being recorded for.
.PARAMETER entitySubComponent
    The name of a sub-component/entity of the IT service/Entity that a metric is being recorded for. This is not required as this level of depth might not be
    needed or possible.
.PARAMETER tagPairs
    The tags to set on the metric. Used to improve querying OpenTSDB. Provided as a Key/Value collection (comparable to pairs of "P").
.PARAMETER metricValue
    The value to record on the metric being writen to OpenTSDB.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the IT service/Entity that a metric is being recorded for.")]
        [ValidateNotNullOrEmpty()]
        [String]$entityName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the component of IT service/Entity that a metric is being recorded for.")]
        [ValidateNotNullOrEmpty()]
        [String]$entityComponent,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="The name of a sub-component/entity of the IT service/Entity that a metric is being recorded for. This is not required as this level of depth might not be needed or possible.")]
        [ValidateNotNullOrEmpty()]
        [String]$entitySubComponent,
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
    $metricInJSON = @{}
    if ($null -eq $entitySubComponent) {
        $metricInJSON.metric = "$entityName.$entityComponent"
    } else {
        $metricInJSON.metric = "$entityName.$entityComponent.$entitySubComponent"
    }
    $metricInJSON.tags =
    $metricInJSON.timestamp = get-date -UFormat %s; # Unix/POSIX Epoch timestamp. Conforming to the OpenTSDB std.
    $metricInJSON.value = $metricValue

    # POST the metric to OpenTSDB
    try {
        $openTSDBendpoint = $OpenTSDBconfig.endpointIP
        $result = Invoke-WebRequest -Uri http://$openTSDBendpoint/api/put -Method post -ContentType "application/json" -body $metricInJSON -UseBasicParsing
    } catch {
        throw "HTTP POST to OpenTSDB on $openTSDBendpoint failed with: $_"
    }

    # Check the result of the POST to OpenTSDB
    # TODO: Maybe this changes in OpenTSDB v2.3 <-- where it migth return HTTP204
    if ($result.openTSDBendpoint) {

    }


}