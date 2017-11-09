function New-HealOpsPackageRunner() {
<#
.DESCRIPTION
    Generates the main script file to be used as the initiating point of execution when invoking a HealOps package.
        - Takes all the *.Tests.ps1 files in the 'TestsAndRepairs' folder
        - Prepares for commenting in the generated script
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    New-HealOpsPackageRunner -PathToTestsAndRepairsFolder $PathToTestsAndRepairsFolder
    Generates a HealOps package runner script. Which should be used to invoke HealOps on the HealOps package.
.PARAMETER PathToTestsAndRepairsFolder
    The full path to the TestsAndRepairs folder of the HealOpsPackage to generate a runner script for. This folder should contain all the *.Tests.ps1 files that the HealOps package
    contain.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
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
    }
    Process {
        $HealOpsTests = Get-ChildItem -Path $PathToTestsAndRepairsFolder -Recurse -File -Force -Include *.Tests.ps1
            if (-not ($null -eq $HealOpsTests)) {
                # Figure out the full path to the TestsAndRepairs folder given
                $fullPathTo_TestsAndRepairsFolder = [System.IO.Path]::GetFullPath($PathToTestsAndRepairsFolder)

                $HealopsPackageRunner_ScriptContent = @"
#Requires -Module HealOps
<#
    - Script for invoking HealOps on FINISH_DESCRIPTION
#>
# The path to the HealOps package config file (JSON)
`$HealOpsPackageConfigPath = "FILL_IN_THE_PATH"

# Invoke HealOps
Invoke-HealOps -TestsFilesRootPath $fullPathTo_TestsAndRepairsFolder -HealOpsPackageConfigPath `$HealOpsPackageConfigPath
"@
                # Create the HealOps package runner script
                try {
                    $tempPath = "$PathToTestsAndRepairsFolder/../RenameMe.ps1"
                    $HealopsPackageRunner_ScriptContent | Add-Content -Path $tempPath -Force -Encoding utf8 -ErrorAction Stop

                    # Inform
                    Write-Host "Successfully generated the HealOps package runner script. Find it here > $tempPath" -ForegroundColor Green
                } catch {
                    Write-Error -Message "Failed to create the HealOps package runner script. Failed with > $_"
                }
            } else {
                Write-Error -Message "No *.Tests.ps1 files found in the folder > $PathToTestsAndRepairsFolder."
            }
    }
    End{}
}
