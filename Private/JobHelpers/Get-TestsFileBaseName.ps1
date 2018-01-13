function Get-TestsFileBaseName() {
<#
.DESCRIPTION
    Derives the base name of the *.Tests.ps1 file. Specifically meaning:
        > Get the filename from the FullName (path) to the *.Tests.ps1 file
        > Remove the file extension
        == Base FileName
.INPUTS
    Inputs (if any)
.OUTPUTS
    [String] representing the base FileName of the *.Tests.ps1 file.
.NOTES
    General notes
.EXAMPLE
    $BaseFileName = Get-TestsFileBaseName -HealOpsPackageConfig $HealOpsPackageConfig -TestsFile $TestsFile
    Explanation of what the example does
.PARAMETER HealOpsPackageConfig
    The HealOps package config file. Represented as an Array.
.PARAMETER TestsFile
    The *.Tests.ps1 file to look up in the HealOps package config file.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The HealOps package config file. Represented as an Array.")]
        [ValidateNotNullOrEmpty()]
        [System.Array]$HealOpsPackageConfig,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The *.Tests.ps1 file..")]
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

        # Now remove the extension. We don't want that in our job name. And the extension is also not in the HealOps package json file.
        # Which is important when looking up the jobInterval in the HealOps package config file.
        $fileNoExt = $TestsFileName -replace $fileExt,""
    }
    End {
        # Return
        $fileNoExt
    }
}