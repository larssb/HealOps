function Install-AvailableUpdate() {
<#
.DESCRIPTION
    Long description
.INPUTS
    <none>
.OUTPUTS
    [Boolean] based on the result of installing an available update.
.NOTES
    General notes
.EXAMPLE
    Install-AvailableUpdate -ModuleName $ModuleName -ProGetServerURI $ProGetServerURI -FeedName $FeedName -Version $Version
    Explanation of what the example does
.PARAMETER ModuleName
    The name of the module that you wish to control if there is an available update to.
.PARAMETER PackageManagementURI
    The URI of the Package Management server.
.PARAMETER FeedName
    The name of the Feed to get the latest version of the module specified in the ModuleName parameter.
.PARAMETER Version
    The version of the module to download, named as specified with the ModuleName parameter.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the module that you wish to control if there is an available update to.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The URI of the Package Management server.")]
        [ValidateNotNullOrEmpty()]
        [String]$PackageManagementURI,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the Feed to get the latest version of the module specified in the ModuleName parameter.")]
        [ValidateNotNullOrEmpty()]
        [String]$FeedName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The version of the module to download, named as specified with the ModuleName parameter.")]
        [ValidateNotNullOrEmpty()]
        [String]$Version
    )

    #############
    # Execution #
    #############
    Begin {
        $API_BaseURI = "$PackageManagementURI/nuget/$FeedName/package"
    }
    Process {
        # Download the module
        try {
            Invoke-WebRequest -Uri "$API_BaseURI/$ModuleName/$Version" -UseBasicParsing -OutFile $PSScriptRoot/Temp/$ModuleName.zip -ErrorAction Stop -ErrorVariable downloadEV
        } catch {
            $log4netLogger.error("Downloading the module named > $ModuleName from the feed named > $FeedName on the package management backend > $PackageManagementURI `
            failed with > $_")
        }

        if (Test-Path -Path $PSScriptRoot/Temp/$ModuleName.zip) {
            # Get the module
            $Module = (Get-Module -ListAvailable $ModuleName | Sort-Object -Property Version -Descending)[0]
            $moduleRoot = Split-Path -Path $module.ModuleBase

            # Extract the package
            try {
                Expand-Archive $PSScriptRoot/Temp/$ModuleName.zip -DestinationPath $moduleRoot/$Version -Force -ErrorAction Stop -ErrorVariable extractEV
            } catch {
                $log4netLogger.error("Failed to extract the nuget package. The extraction failed with > $_")
            }

            if (Test-Path -Path $moduleRoot/$Version) {
                try {
                    # Remove older versions of the module
                    Remove-Item -Path $moduleRoot -Exclude $Version -Recurse -Force -ErrorAction Stop

                    # Return
                    $true
                } catch {
                    $log4netLogger.error("Failed to remove older versions of the updated module. It failed with > $_")

                    # Return
                    $false
                }
            } else {
                # Return
                $false
            }
        } else {
            $log4netLogger.error("The nuget package could not be found. Was it downloaded successfully?")

            # Return
            $false
        }
    }
    End {}
}