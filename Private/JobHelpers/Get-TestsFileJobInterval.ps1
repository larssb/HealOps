function Get-TestsFileJobInterval() {
<#
.DESCRIPTION
    Determines the repeat interval for a job running a *.Tests.ps1 file. Determined by reading the 'jobInterval' property in the HealOps package config file.
.INPUTS
    [System.Array]HealOpsPackageConfig. The HealOps config file. Converted from JSON to an Array.
    [System.IO.FileSystemInfo]TestsFile. File info on a specific *.Tests.ps1 file.
.OUTPUTS
    [int] representing the value by which a job executing a *.Tests.ps1 file should repeat.
.NOTES
    <none>
.EXAMPLE
    [int]jobInterval = Get-TestsFileJobInterval -HealOpsPackageConfig $HealOpsPackageConfig -TestsFile $TestsFile
    Explanation of what the example does
.PARAMETER HealOpsPackageConfig
    The HealOps package config file. Represented as an Array.
.PARAMETER TestsFile
    The *.Tests.ps1 file to look up in the HealOps package config file.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName="Default")]
    [OutputType([Int])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Array]$HealOpsPackageConfig,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileSystemInfo]$TestsFile
    )

    #############
    # Execution #
    #############
    Begin {}
    Process {
        # Get only the filename from the FullName (path) to the file
        $TestsFileName = Split-Path -Path $TestsFile -Leaf

        # Get the filetype extension
        $fileExt = [System.IO.Path]::GetExtension($TestsFileName)

        # Now remove the extension. We don't want that in our job name.
        $fileNoExt = $TestsFileName -replace $fileExt,""
        $TestsFileJobInterval = $HealOpsPackageConfig.$fileNoExt.jobInterval
        Write-Verbose -Message "The job repetition interval will be > $TestsFileJobInterval"
    }
    End {}
}