function Get-AvailableUpdate() {
<#
.DESCRIPTION
    Long description
.INPUTS
    <none>
.OUTPUTS
    [HashTable] containing either info to be used when downloading an update or no info implying that there is either no newer version available or that the package is not available
    on the package management backend.
.NOTES
    General notes
.EXAMPLE
    Test-AvailableUpdate
    Explanation of what the example does
.PARAMETER ModuleName
    The name of the module that you wish to control if there is available updates to.
.PARAMETER Config
    The config file holding package management repository info. Of the PSCustomObject type.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([HashTable])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the module that you wish to control if there is an available update to.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The current version of the module that you wish to control if there is an available update to.")]
        [ValidateNotNullOrEmpty()]
        $CurrentModuleVersion,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The config file holding package management repository info. Of the PSCustomObject type.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config
    )

    #############
    # Execution #
    #############
    # Get the latest version of the module
    $latestModuleVersion = Get-LatestModuleVersion -PackageManagementURI $Config.PackageManagementURI -FeedName $Config.FeedName -ModuleName $ModuleName -APIKey $Config.PackageManagementAPIKey
    Write-Verbose -Message "latest ver. > $latestModuleVersion and curent ver. > $CurrentModuleVersion for the module named $ModuleName"
    $log4netLoggerDebug.debug("latest ver. > $latestModuleVersion and curent ver. > $CurrentModuleVersion for the module named $ModuleName")

    <#
        - Convert Strings to number type
    #>
    [float]$lVersionReturnedFloat = 0.0
    [bool]$lVersionResult = [float]::TryParse($latestModuleVersion, [ref]$lVersionReturnedFloat)
    if ($lVersionResult -eq $false) {
        Write-Verbose -Message "Could not convert the String (latestModuleVersion) to a number."
        $log4netLogger.error("Could not convert the String (latestModuleVersion) to a number.")
    }

    [float]$cVersionReturnedFloat = 0.0
    [bool]$cVersionResult = [float]::TryParse($CurrentModuleVersion, [ref]$cVersionReturnedFloat)
    if ($cVersionResult -eq $false) {
        Write-Verbose -Message "Could not convert the String (CurrentModuleVersion) to a number."
        $log4netLogger.error("Could not convert the String (CurrentModuleVersion) to a number.")
    }

    # Compare versions and return the result to caller
    $updateInfo = @{}
    $log4netLoggerDebug.debug("latest version returned value > $lVersionReturnedFloat and current version returned value > $cVersionReturnedFloat")
    if ($lVersionResult -eq $true -and $cVersionResult -eq $true) {
        if ($lVersionReturnedFloat -gt $cVersionReturnedFloat) {
            $updateInfo.Add("Version",$latestModuleVersion)

            # Return
            $updateInfo
        } else {
            # Return
            $updateInfo
        }
    } else {
        # Return
        $updateInfo
    }
}