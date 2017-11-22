function Test-ModuleUpdated() {
<#
.DESCRIPTION
    Long description
.INPUTS
    <none>
.OUTPUTS
    <none>
.NOTES
    General notes
.EXAMPLE
    Test-ModuleUpdated -ModuleName $ModuleName -ModuleVersionBeforeUpdate $ModuleVersionBeforeUpdate
    Explanation of what the example does
.PARAMETER ModuleName
    The name of the PowerShell module to test whether it was updated.
.PARAMETER ModuleVersionBeforeUpdate
    The version of the module prior to executing update-module.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the PowerShell module to test whether it was updated.")]
        [ValidateNotNullOrEmpty()]
        $ModuleName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The version of the module prior to executing update-module.")]
        [ValidateNotNullOrEmpty()]
        $ModuleVersionBeforeUpdate
    )

    #############
    # Execution #
    #############
    # Control if the module was actually updated
    $moduleVersionAfterUpdate = Get-module -Name $ModuleName

    if ($moduleVersionAfterUpdate.Version -gt $ModuleVersionBeforeUpdate) {
        # Log it
        $log4netLoggerDebug.debug("The module $ModuleName was bumped to $($moduleVersionAfterUpdate.Version) from $moduleVersionBeforeUpdate")

        # When in verbose mode
        Write-Verbose -Message "The module $ModuleName was bumped to $($moduleVersionAfterUpdate.Version) from $moduleVersionBeforeUpdate"
    } else {
        # Log it
        $log4netLoggerDebug.debug("There was no update available on the Package Management backend. The module $ModuleName was therefore not updated. `
        Module version before the update > $ModuleVersionBeforeUpdate. Module version after trying an update > $($moduleVersionAfterUpdate.Version)")

        # When in verbose mode
        Write-Verbose -Message "There was no update available on the Package Management backend. The module $ModuleName was therefore not updated. `
        Module version before the update > $ModuleVersionBeforeUpdate. Module version after trying an update > $($moduleVersionAfterUpdate.Version)"
    }
}