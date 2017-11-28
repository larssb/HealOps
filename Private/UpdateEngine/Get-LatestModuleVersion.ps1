function Get-LatestModuleVersion() {
<#
.DESCRIPTION
    Long description
.INPUTS
    <none>
.OUTPUTS
    [String] representing the latest version of the module being looked up.
.NOTES
    General notes
.EXAMPLE
    Get-LatestModuleVersion -ProGetServerURI https://proget.test.com/ -FeedName MyFeed -ModuleName MyModule -APIKey "fwf292902382909fe9f"
    Explanation of what the example does
.PARAMETER ProGetServerURI
    The URI of the ProGet package management server.
.PARAMETER FeedName
    The name of the Feed to get the latest version of the module specified in the ModuleName parameter.
.PARAMETER ModuleName
    The name of the module for which to look for the latest version.
.PARAMETER APIKey
    The API key with which to authenticate to the package management backend.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The URI of the Package Management server.")]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the Feed to get the latest version of the module specified in the ModuleName parameter.")]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the module for which to look for the latest version.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The API key with which to authenticate to the package management backend.")]
        [ValidateNotNullOrEmpty()]
        $APIKey
    )

    #############
    # Execution #
    #############
    Begin {
        $API_BaseURI = "$PackageManagementURI/api/json"
    }
    Process {
        # Retrieve the ID for the feed
        try {
            $Request = Invoke-WebRequest -Uri "$API_BaseURI/Feeds_GetFeed?API_Key=$APIKey&Feed_Name=$FeedName" -UseBasicParsing -ErrorAction Stop
        } catch {
            $log4netLogger.error("Requesting the ID of the feed $FeedName on package management backend $PackageManagementURI failed with > $_")
        }
        $Feed = $Request.Content | ConvertFrom-Json

        # Retrieve the package and version requested
        $URI = "$API_BaseURI/NuGetPackages_GetLatest?API_Key=$APIKey&Feed_Id=" + $Feed.Feed_Id + "&PackageIds_Psv=$ModuleName"
        try {
            $Request = Invoke-WebRequest -Uri $URI -UseBasicParsing -ErrorAction Stop
        } catch {
            $log4netLogger.error("Retrieving the package and version on the package management backend $PackageManagementURI failed with > $_")
        }
        $PackageVersion = $Request.Content | ConvertFrom-Json
        Write-Output($PackageVersion.Version_Text)
    }
    End {}
}