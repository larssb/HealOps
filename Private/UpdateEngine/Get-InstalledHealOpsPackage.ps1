function Get-InstalledHealOpsPackage() {
<#
.DESCRIPTION
    Retrieves locally installed HealOps packages.
.INPUTS
    [String] representing one or more HealOps packages to retrieve. (The Package parameter)
    [Switch] indicating that the HealOps packages to retrieve are those NOT specified via the Package parameter.
.OUTPUTS
    [System.Collections.Generic.List[PSModuleInfo] containing HealOps packages installed locally. Relatiev to the input to this functions parameters.
.NOTES
    <none>
.EXAMPLE
    [ArrayList]$list = Get-InstalledHealOpsPackage -Package "My.HealOpsPackage","MyOther.HealOpsPackage"
        > Specifies that all locally installed HealOps packages should be retrieved.
.PARAMETER All
    Indicates that all HealOps packages should be retrieved.
.PARAMETER NotIn
    Indicates that the HealOps packages to retrieve are those NOT specified via the Package parameter.
.PARAMETER Package
    One or more HealOps packages to retrieve.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSModuleInfo]])]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="All", HelpMessage="Indicates that all HealOps packages should be retrieved.")]
        [Switch]$All,
        [Parameter(Mandatory=$false, ParameterSetName="Specific", HelpMessage="Indicates that the HealOps packages to retrieve are those NOT specified via the Package parameter.")]
        [Switch]$NotIn,
        [Parameter(Mandatory=$true, ParameterSetName="Specific", HelpMessage="One or more HealOps packages to retrieve.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Package
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Variables
        #>
        $packageList = New-Object System.Collections.Generic.List[PSModuleInfo]
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Specific') {
            # Retrieve specific HealOps package/s
            if ($NotIn) {
                # NotIn was used. Filter the HealOps packages retrieved
                $Packages = Get-Module -Name *HealOpsPackage* -ListAvailable -ErrorAction Stop | Where-Object { $_.Name -notin $Package }
            } else {
                # Get the HealOps packages specified via the Package parameter
                $Packages = Get-Module -Name *HealOpsPackage* -ListAvailable -ErrorAction Stop | Where-Object { $_.Name -in $Package }
            }
        } else {
            # Retrieve all HealOps packages
            try {
                # Get the installed HealOps packages
                $Packages = Get-Module -Name *HealOpsPackage* -ListAvailable -ErrorAction Stop
            } catch {
                $log4netLogger.error("Getting the installed HealOps packages failed with > $_")
            }

        }

        if ($null -ne $Packages) {
            # Filter so that we end up with only 1 HealOpsPackage version per installed HealOps package.
            $filteredPackages = $Packages | Select-Object -Unique

            # Add the retrieved HealOps packages to the list
            foreach ($Package in $filteredPackages) {
                $packageList.Add($package)
            }
        } else {
            $log4netLoggerDebug.debug("No HealOps packages found on the system. Searched on > '*HealOpsPackage*'")
        }
    }
    End {
        # Return
        $packageList
    }
}