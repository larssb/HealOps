function Update-TestRunningStatus() {
<#
.DESCRIPTION
    Updates or creates a json file relative to the test running, in order to be able to determine if a test is currently running or not. Needed because when running all the tests in
    "X" folder each test will be started via the Start-Job cmdlet.
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    - If the file does not already exist it will be created.
    - If it exists its contents will be overwritten.
.EXAMPLE
    Update-TestRunningStatus -TestsFilesRootPath $TestsFilesRootPath -TestFileName $TestFileName
    Updates the .json file relative to the Tests file specified via the TestFileName parameter. This will mark the test as not running because the TestRunning switch parameter is not used.
.PARAMETER TestsFilesRootPath
    The folder that contains the tests to execute.
.PARAMETER TestFileName
    The name of the *.Tests.ps1 file.
.PARAMETER TestRunning
    Set this switch to indicate that the test is running.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage=" The folder that contains the tests to execute.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestsFilesRootPath,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the *.Tests.ps1 file.")]
        [ValidateNotNullOrEmpty()]
        [String]$TestFileName,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Set this switch to indicate that the test is running.")]
        [Switch]$TestRunning
    )

    #############
    # Execution #
    #############
    <#
        - Define data for updating the status of a test
    #>
    # Remove the extension from the Tests file name
    $fileExtension = [System.IO.Path]::GetExtension($TestFileName)
    $TestFileName_NoExt = $TestFileName -replace "$fileExtension",""

    # Remove the .Tests part of the filename
    $statusFileName = $TestFileName_NoExt -replace "Tests","Status"

    # Define the object that will be written to the tests *.Status.json file.
    $tempTestsCollection = @{}
    $tempTestsCollection.Add("name",$statusFileName)
    $tempTestsCollection.Add("running",$($TestRunning.ToString()))

    <#
        - Write the update to the status file
    #>
    # Convert to JSON
    $tempTestsCollection_InJSON = ConvertTo-Json -InputObject $tempTestsCollection -Depth 3
    Write-Verbose -Message "Status JSON to write to the $TestFileName status file > $tempTestsCollection_InJSON"

    # Write the file
    try {
        Set-Content -Path $TestsFilesRootPath/$statusFileName.json -Value $tempTestsCollection_InJSON -Force -Encoding UTF8
    } catch {
        # Log it

        throw "Failed to write the status file for the tests file > $TestFileName. Failed with > $_"
    }
}