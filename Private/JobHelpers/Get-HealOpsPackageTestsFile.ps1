function Get-HealOpsPackageTestsFile() {
<#
.DESCRIPTION
    Retrieves *.Tests.ps1 files in the TestsAndRepairs folder in a HealOps package.
.INPUTS
    [String] representing the HealOps package to retrieve *.Tests.ps1 files in.
.OUTPUTS
    [System.Array] containing *.Tests.ps1 files. Or an empty list.
.NOTES
    <none>
.EXAMPLE
    $TestsFiles = Get-HealOpsPackageTestsFile -Package "My.HealOpsPackage"
        > Retrieves all the *.Tests.ps1 files in the HealOps package named "My.HealOpsPackage"
.PARAMETER All
    Use this parameter to specify that you want all the *.Tests.ps1 files in the HealOps package.
.PARAMETER Package
    The name of a package in which to get HealOps *.Tests.ps1 files in.
        > [PSModuleInfo]
.PARAMETER TestsFileName
    The name of the specific *.Tests.ps1 file you wish to retrieve.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(ParameterSetName="All")]
        [switch]$All,
        [Parameter(Mandatory, ParameterSetName="All")]
        [Parameter(Mandatory, ParameterSetName="Specific")]
        [ValidateNotNullOrEmpty()]
        [PSModuleInfo]$Package,
        [Parameter(Mandatory, ParameterSetName="Specific")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsFileName
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        $log4netLoggerDebug.debug("Get-HealOpsPackageTestsFile > The module base of the HealOps package named $Package is > $($Package.ModuleBase)")
        if ($PSCmdlet.ParameterSetName -eq "Specific") {
            # Get the specified *.Tests.ps1 file
            try {
                [Array]$TestsFiles = Get-ChildItem -Path "$($Package.ModuleBase)/TestsAndRepairs" -File -Recurse -Force -Include "$TestsFileName"
            } catch {
                $log4netLogger.error("Get-HealOpsPackageTestsFile > Getting the specific *.Tests.ps1 file, named > $TestsFileName, failed with > $_")
            }
        } else {
            # Get all the *.Tests.ps1 files in the HealOps package
            try {
                [Array]$TestsFiles = Get-ChildItem -Path "$($Package.ModuleBase)/TestsAndRepairs" -File -Recurse -Force -Include "*.Tests.ps1"
            } catch {
                $log4netLogger.error("Get-HealOpsPackageTestsFile > Getting *.Tests.ps1 file failed with > $_")
            }
        }

        # Control that TestsFiles contains elements
        if (-not $TestsFiles.Count -ge 1) {
            # Return an empty list instead of throwing.
            [Array]$TestsFiles = @()
        }
    }
    End {
        # Return
        ,$TestsFiles
    }
}