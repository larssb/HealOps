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
        # Define shared variables (shared between PS versions)
        $API_BaseURI = "$PackageManagementURI/nuget/$FeedName/package"

        <#
            - Remove the module folder if it is already present - PS v4 and below
        #>
        if(-not $psVersionAbove4) {
            # Determine folders to use
            $modulePackagePath = "$ModuleExtractionPath/$ModuleName.zip"
            $psProgramFilesModulesPath = Get-PSProgramFilesModulesPath
            $moduleRoot = "$psProgramFilesModulesPath/$ModuleName"

            # Remove
            if(Test-Path -Path $moduleRoot) {
                try {
                    if($ModuleName -eq "HealOps" -or $ModuleName -eq "powerShellTooling" -or $ModuleName -eq "Pester") {
                        # Exclude the Artefacts folder (HealOps and PowerShellTooling) and the lib folder (Pester) in order to avoid exceptional behavior because of files being locked. We would also like to keep logs and so forth.
                        $elementsToRemove = Get-ChildItem -Path $moduleRoot -Force -Exclude "Artefacts","lib" -ErrorAction Stop
                    } else {
                        $elementsToRemove = Get-ChildItem -Path $moduleRoot -Force -ErrorAction Stop
                    }

                    $elementsToRemoveEnumerator = $elementsToRemove.GetEnumerator()
                    foreach ($element in $elementsToRemoveEnumerator) {
                        if($element.GetType().Name -eq "DirectoryInfo") {
                            # The element is a folder. Get all its children and remove these.
                            Get-ChildItem -Path $element.FullName -Force -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop # Using Get-childitem and piping to be compatible with PSv3

                            # Remove the folder itself
                            Remove-Item -Path "$($element.FullName)" -Force -ErrorAction Stop
                        } else {
                            # The element is a file
                            Remove-Item -Path "$($element.FullName)" -Force -Recurse -ErrorAction Stop
                        }
                    }
                } catch {
                    throw "Failed to remove the already existing module folder, for the module named $ModuleName (prep. for installing the module on a system with a PowerShell version `
                    that do not support module versioning). It failed with > $_"
                }
            }
        } else {
            # Determine folders to use
            $modulePackagePath = "$PSScriptRoot/../../Artefacts/Temp/$ModuleName.zip"
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
            $log4netLoggerDebug.debug("The value of the ModuleExtractionPath variable is > $ModuleExtractionPath")

            if(Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue) {
                #####################
                # PS v5+ compatible #
                #####################
                try {
                    # Extract the package
                    Expand-Archive $modulePackagePath -DestinationPath $ModuleExtractionPath -Force -ErrorAction Stop -ErrorVariable extractEV
                    $installationResult = $true
                } catch {
                    $log4netLogger.error("Failed to extract the nuget package. The extraction failed with > $_")
                    $installationResult = $false
                }
            } else {
                #####################
                # PS v5- compatible #
                #####################
                try {
                    # Add the .NET compression class to the current session
                    Add-Type -Assembly System.IO.Compression.FileSystem

                    # Extract the zip file
                    [System.IO.Compression.ZipFile]::ExtractToDirectory("$modulePackagePath", "$ModuleExtractionPath")
                    $installationResult = $true
                } catch {
                    $log4netLogger.error("Failed to extract the nuget package. The extraction failed with > $_")
                    $installationResult = $false
                }

                if ($installationResult) {
                    try {
                        # Move the files from the extraction dir. to the root module dir.
                        Get-ChildItem -Path $ModuleExtractionPath -Exclude "Artefacts","lib","$ModuleName.zip" -Force -ErrorAction Stop | Move-Item -Destination "$moduleRoot" -Force -ErrorAction Stop
                    } catch {
                        $log4netLogger.error("Moving module files to the correct dir failed with > $_")
                        $installationResult = $false
                    }
                }
            }

            if ( (Test-Path -Path $ModuleExtractionPath) -and ($installationResult -eq $true)) {
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