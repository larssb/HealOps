﻿###################
# FUNCTION - PREP #
###################
#Requires -

####################
# FUNCTION - START #
####################
function Invoke-HealOps() {
<#
.DESCRIPTION
    Invoke-HealOps is the function you call to initiate a HealOps package. Thereby testing "X" infrastructure.
    Where "X" could be n+m.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Outputs (if any)
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.PARAMETER NAME_OF_THE_PARAMETER_WITHOUT_THE_QUOTES
    Parameter HelpMessage text
    Add a .PARAMETER per parameter
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath
    )

    #############
    # Execution #
    #############
    Begin {

    }
    Process {
        # TODO: Think of supporting that 1 could just specify a folder and the all files will be picked up
        if (Test-Path -Path $TestFilePath) {
            # Run the test
            $testResult = Test-EntityState -TestFilePath $TestFilePath;

            # Control for any failed tests
            if ($testResult.Count -ge 1) {
                # iterate over the failed tests & invoke repairs matching the failed test
                foreach ($failedTest in $testResult) {
                    Repair-EntityState -Repair $failedTest.ID -TestFilePath $TestFilePath
                }
            }
        } else {
            throw "The file does not exist: $_";
        }
    }
    End {}
}
##################
# FUNCTION - END #
##################