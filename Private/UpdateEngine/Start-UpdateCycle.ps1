function Start-UpdateCycle() {
<#
.DESCRIPTION
    Updates a PowerShell module and its dependencies. This function expects that a Package Management is used to hold the module
    and its dependencies.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    Start-UpdateCycle -ModuleName $ModuleName -Config $Config
    Start an update cycle so that the module specified as well as its dependencies is updated
.PARAMETER ModuleName
    The name of the PowerShell module to update.
.PARAMETER Config
    The config file holding package management repository info. Of the PSCustomObject type
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the PowerShell module to update.")]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The config file holding package management repository info. Of the PSCustomObject type")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Config
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Prep. and sanity checks
        #>
        # Check for the temp download folder
        $tempDirPath = "$PSScriptRoot/Temp"
        if (-not (Test-Path -Path $tempDirPath)) {
            try {
                New-Item -Path $PSScriptRoot -Name "Temp" -ItemType Directory -Force -ErrorAction Stopv | Out-Null
            } catch {
                $log4netLogger.error("Failed to create the temp download folder. The failure was > $_")
            }
        }

        # Get the main module. The newest version of it, if several is installed
        $MainModule = (Get-Module -ListAvailable $ModuleName | Sort-Object -Property Version -Descending)[0]
        $MainModuleRoot = Split-Path -Path $MainModule.ModuleBase
    }
    Process {
        <#
            - The dependencies of the module
        #>
        foreach ($requiredModule in $MainModule.RequiredModules) {
            # Register the current version of the module
            $moduleVersionBeforeUpdate = $requiredModule.version

            # Check the Package Management backend for an available update to the current dependency module
            $availableUpdateResult = Get-AvailableUpdate -ModuleName $requiredModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate -Config $Config

            if ($null -ne $availableUpdateResult.Version) {
                # Get the module. The newest version of it, if several is installed
                $requiredModule = (Get-Module -ListAvailable $requiredModule.Name | Sort-Object -Property Version -Descending)[0]
                $requiredModuleRoot = Split-Path -Path $requiredModule.ModuleBase

                # Update the module
                $installResult = Install-AvailableUpdate -ModuleName $requiredModule.Name -ModuleBase $requiredModuleRoot -PackageManagementURI $config.PackageManagementURI -FeedName $Config.FeedName -Version $availableUpdateResult.Version

                if ($installResult -eq $true) {
                    # Control if the module was actually updated after a non-failing Install-AvailableUpdate execution and log it
                    Test-ModuleUpdated -ModuleName $requiredModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate
                }
            } else {
                $log4netLoggerDebug.debug("There was no newer version of the module: $($requiredModule.Name) - on the Package Management backend.")
            }
        }

        <#
            - The main module
        #>
        # Register the current version of the module
        $moduleVersionBeforeUpdate = $MainModule.Version

        # Check the Package Management backend for an available update to the current dependency module
        $availableUpdateResult = Get-AvailableUpdate -ModuleName $MainModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate -Config $Config

        if ($null -ne $availableUpdateResult.Version) {
            # Update the module
            $installResultMainModule = Install-AvailableUpdate -ModuleName $MainModule.Name -ModuleBase $MainModuleRoot -PackageManagementURI $config.PackageManagementURI -FeedName $Config.FeedName -Version $availableUpdateResult.Version

            if ($installResultMainModule -eq $true) {
                # Control if the module was actually updated after a non-failing Install-AvailableUpdate execution and log it
                Test-ModuleUpdated -ModuleName $MainModule.Name -CurrentModuleVersion $moduleVersionBeforeUpdate
            }
        } else {
            $log4netLoggerDebug.debug("There was no newer version of the module: $($MainModule.Name) - on the Package Management backend.")
        }
    }
    End {
        <#
            - Clean-up & finalization
        #>
        if($installResult -eq $true -or $installResultMainModule -eq $true) {
            # Remove the contents of the download temp dir.
            try {
                Remove-Item -Path $tempDirPath -Force -Recurse -Include *.zip -ErrorAction Stop
            } catch {
                $log4netLogger.error("Cleaning up the download temp dir > $tempDirPath faild with > $_")
            }
        }

        if($installResultMainModule -eq $true) {
            # Register that the main module was updated.
            $registerResult = Register-UpdateCycle -Config $Config -Version $availableUpdateResult.Version -ModuleBase $MainModuleRoot
            if ($registerResult -eq $false) {
                $log4netLogger.error("Failed to register that an update cycle ran. CASE > The main module was updated.")
            }
        } else {
            # Register that an update cycle was ran. But register to the current version of the main module as it was not updated.
            $registerResult = Register-UpdateCycle -Config $Config -Version $moduleVersionBeforeUpdate -ModuleBase $MainModuleRoot
            if ($registerResult -eq $false) {
                $log4netLogger.error("Failed to register that an update cycle ran. CASE > The main module was NOT updated.")
            }
            $log4netLoggerDebug.debug("The main module was not updated. See other entries in the logs for possible reasons. Where one reason of course could be that there was no update.")
        }
    }
}