function Get-AvailableUpdate() {
<#
.DESCRIPTION
    Compares the current version of a module with the latest version of the same module on a package management backend. In order to determine if the current version is behind.
        - If behind >> the latest available version number is returned.
        - If there is no newer version >> an empty collection is returned.
.INPUTS
    [PSCustomObject]Config. HealOps config data.
    $CurrentModuleVersion.  The current version of the a PowerShell module.
    [String]ModuleName. The name of a PowerShell module.
.OUTPUTS
    [HashTable] containing either info to be used when downloading an update or no info implying that there is either no newer version available or that the package is not available
    on the package management backend.
.NOTES
    <none>
.EXAMPLE
    $AvailableUpdate = Get-AvailableUpdate -ModuleName "MyModule" -CurrentModuleVersion "1.0.0" -Config $Config
    Checks if a newer version of MyModule is available.
.PARAMETER Config
    The config file holding package management repository info.
.PARAMETER CurrentModuleVersion
    The current version of a PowerShell module on which to control if a newer version exists.
.PARAMETER ModuleName
    The name of the module on which you wish to control if a newer version exists.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([HashTable])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $CurrentModuleVersion,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName
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