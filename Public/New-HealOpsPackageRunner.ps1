##Requires -
function New-HealOpsPackageRunner() {
<#
.DESCRIPTION
    Generates the main script file to be used as the initiating point of execution when invoking a HealOps package.
        - Takes all the *.Tests.ps1 files in the 'TestsAndRepairs' folder
        - Generates a line per *.Tests.ps1 file in the generated script
        - Prepares for commenting in the generated script
.INPUTS
    Inputs (if any)
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    New-HealOpsPackageRunner -PathToTestsAndRepairsFolder
    Explanation of what the example does
.PARAMETER PathToTestsAndRepairsFolder
    The full path to the TestsAndRepairs folder of the HealOpsPackage to generate a runner script for.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The full path to the TestsAndRepairs folder of the HealOpsPackage to generate a runner script for.")]
        [ValidateNotNullOrEmpty()]
        $PathToTestsAndRepairsFolder
    )

    #############
    # Execution #
    #############
    Begin {
        # Test that the path actually existss
        if(-not (Test-Path -Path $PathToTestsAndRepairsFolder)) {
            Write-Error -Message "The path you provided does not exist."
            break
        }

        # Try to get the config file for the HealOpsPackage
        $dirSeparator = [System.IO.Path]::DirectorySeparatorChar

        $HealOpsPackageConfig = Get-ChildItem -Path $PSScriptRoot/.. -Recurse -File -Force -Include *.json
        if (-not ($null -eq $HealOpsPackageConfig) -and -not ($HealOpsPackageConfig.count -gt 1)) {
            "hi"
            $HealOpsPackageConfig
            $HealOpsPackageConfig.Count
        }
    }
    Process {

    }
    End{}
}