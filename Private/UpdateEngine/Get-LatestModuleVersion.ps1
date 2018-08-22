function Get-LatestModuleVersion() {
<#
.DESCRIPTION
    Gets the latest version of a package on a package management system.
.INPUTS
    [String]APIKey. Representing the APIKey to authentiate with on the package management system.
    [String]FeedName. The name of the feed to query for the latest version of [String]ModuleName.
    [String]ModuleName. The name of the module to get the latest version of on the package management system.
    [String]PackageManagementURI. The URI of the package management system.
.OUTPUTS
    [String] representing the latest version of the module being looked up.
.NOTES
    <none>
.EXAMPLE
    Get-LatestModuleVersion -PackageManagementURI https://proget.test.com/ -FeedName MyFeed -ModuleName MyModule -APIKey "fwf292902382909fe9f"
    Queries the package management system on https://proget.test.com/ for the latest version of a package named MyModule on the feed MyFeed. Authenticating with the
    APIKey "fwf292902382909fe9f".
.PARAMETER APIKey
    The API key with which to authenticate to the package management backend.
.PARAMETER FeedName
    The name of the Feed to get the latest version of the module specified in the ModuleName parameter.
.PARAMETER ModuleName
    The name of the module for which to look for the latest version.
.PARAMETER PackageManagementURI
    The URI of the package management system to be used by HealOps.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([String])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$APIKey,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI
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
    }
    End {
        # Return
        Write-Output($PackageVersion.Version_Text)
    }
}