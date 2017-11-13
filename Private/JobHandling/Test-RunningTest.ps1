function Test-RunningTest() {
<#
.DESCRIPTION
    Reads a *.Status.json file in order to determine the running status of "X" test.
.INPUTS
    <none>
.OUTPUTS
    [Boolean] corresponding to the result of testing if "X" test is already running.
.NOTES
    General notes
.EXAMPLE
    Test-RunningTest -TestFileName $TestFileName -TestsFilesRootPath $TestsFilesRootPath
    Read the *.Status.json file specific to the test in question in order to determine if "X" test is already running.
.PARAMETER TestFileName
    The name of the *.Tests.ps1 file.
.PARAMETER TestsFilesRootPath
    The folder that contains the tests to execute.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the *.Tests.ps1 file.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestFileName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage=" The folder that contains the tests to execute.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsFilesRootPath
    )

    #############
    # Execution #
    #############
    # Remove the extension from the Tests file name in order to reflect the filename on disk
    $fileExtension = [System.IO.Path]::GetExtension($TestFileName)
    $TestFileName_NoExt = $TestFileName -replace "$fileExtension",""

    # Remove the .Tests part of the filename
    $statusFileName = $TestFileName_NoExt -replace "Tests","Status"

    if(-not (Test-Path -Path $TestsFilesRootPath/$statusFileName.json)) {
        # The *.Status.json file does not exsit. Leads us to conclude that the test in question is not running
        $false
    } else {
        # Read in the *.Status.json file
        $statusJSONfile = Get-Content -Path $TestsFilesRootPath/$statusFileName.json -Encoding UTF8 | ConvertFrom-Json
        Write-Verbose -Message "The status file data > $statusJSONfile"

        # Get the runnig status of the test
        $runningStatus = $statusJSONfile.running

        # Control the status
        if ($runningStatus -eq "True") {
            # The test is running
            $true

            Write-Verbose -Message "here"
        } else {
            $false
        }
    }
}