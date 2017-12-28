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
    Install-AvailableUpdate -ModuleName $ModuleName -PackageManagementURI $PackageManagementURI -FeedName $FeedName -Version $Version
    Explanation of what the example does
.PARAMETER ModuleName
    The name of the module that you wish to control if there is an available update to.
.PARAMETER PackageManagementURI
    The URI of the Package Management server.
.PARAMETER FeedName
    The name of the Feed to get the latest version of the module specified in the ModuleName parameter.
.PARAMETER Version
    The version of the module to download, named as specified with the ModuleName parameter.
.PARAMETER ModuleExtractionPath
    The path to extract the module to.
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
        [String]$Version,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The path to extract the module to.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleExtractionPath
    )

    #############
    # Execution #
    #############
    Begin {
        # Define variables
        $API_BaseURI = "$PackageManagementURI/nuget/$FeedName/package"
        $modulePackagePath = "$PSScriptRoot/Temp/$ModuleName.zip"

        # Remove the module folder if it is already present - PS v4 and below
        if(-not $psVersionAbove4) {
            if(Test-Path -Path $ModuleExtractionPath) {
                try {
                    Remove-Item -Path $ModuleExtractionPath -Force -Recurse -ErrorAction Stop
                } catch {
                    throw "Failed to remove the already existing module folder, for the module named $ModuleName (prep. for installing the module on a system with a PowerShell version `
                    that do not support module versioning). It failed with > $_"
                }
            }
        }
    }
    Process {
        # Download the module
        try {
            Invoke-WebRequest -Uri "$API_BaseURI/$ModuleName/$Version" -UseBasicParsing -OutFile $modulePackagePath -ErrorAction Stop -ErrorVariable downloadEV
        } catch {
            $log4netLogger.error("Downloading the module named > $ModuleName from the feed named > $FeedName on the package management backend > $PackageManagementURI `
            failed with > $_")
        }

        if (Test-Path -Path $modulePackagePath) {
            # Extract the package
            try {
                if(Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue) {
                    Expand-Archive $modulePackagePath -DestinationPath $ModuleExtractionPath -Force -ErrorAction Stop -ErrorVariable extractEV
                    $expandArchiveResult = $true
                } else {
                    # Add the .NET compression class to the current session
                    Add-Type -Assembly System.IO.Compression.FileSystem

                    # Extract the zip file
                    [System.IO.Compression.ZipFile]::ExtractToDirectory("$modulePackagePath", "$ModuleExtractionPath")
                }
            } catch {
                $log4netLogger.error("Failed to extract the nuget package. The extraction failed with > $_")
                $expandArchiveResult = $false
            }

            if ( (Test-Path -Path $ModuleExtractionPath) -and ($expandArchiveResult -eq $true)) {
                # Return
                $true
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