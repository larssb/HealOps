# Define parameters
[CmdletBinding()]
[OutputType([Boolean])]
param(
    [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Data from the result of testing the state of an IT Service/Entity.")]
    [ValidateNotNullOrEmpty()]
    $TestData
)

#############
# Execution #
#############
Write-Verbose -Message "Trying to remediate the Octopus Deploy tentacle as it was in a failed state"

# Parse the incoming test data to determine what remediating effort to try
if($TestData.FailureMessage -eq 503) {
    # Service unavailable. Let's try a service restart
    $svc = Get-Service -Name "OctopusDeploy Tentacle"
    if($null -ne $svc) {
        try {
            Start-Service $svc

            $remediationResult = $true
        } catch {
            Write-Output "Failed to start the Octopus Deploy service. Failed with: $_"

            $remediationResult = $false
        }
    } else {
        # Report that the server is missing on the node.
        $remediationResult = $false
    }

    # Report on the result of the remediation

    # Return to caller
    $remediationResult
}