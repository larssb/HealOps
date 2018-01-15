function Get-InstalledHealOpsPackage() {
<#
.DESCRIPTION
    Retrieves locally installed HealOps packages.
.INPUTS
    [String[]] representing one or more HealOps packages to retrieve. (The Package parameter)
        > OR A
    [System.Collections.Generic.List] representing one or more HealOps packages to retrieve. (The PackageList parameter)
    [Switch] indicating that the HealOps packages to retrieve are those NOT specified via the Package parameter.
    [Switch] -All to simply declare that all locally installed HealOps packages should be retrieved.
.OUTPUTS
    [System.Collections.Generic.List[PSModuleInfo] containing HealOps packages installed locally. Relative to the input to this functions parameters.
.NOTES
    <none>
.EXAMPLE
    [System.Collections.Generic.List[PSModuleInfo]]$list = Get-InstalledHealOpsPackage -Package "My.HealOpsPackage","MyOther.HealOpsPackage"
        > Specifies that all locally installed HealOps packages should be retrieved.
.EXAMPLE
    [System.Collections.Generic.List[PSModuleInfo]]$list = Get-InstalledHealOpsPackage -Package "My.HealOpsPackage"
        > My.HealOpsPackage will be retrieved from the local system. If it is found/installed.
.PARAMETER All
    Indicates that all HealOps packages should be retrieved.
.PARAMETER NotIn
    Indicates that the HealOps packages to retrieve are NOT the ones specified via the Package parameter.
.PARAMETER Package
    One or more HealOps packages to retrieve.
.PARAMETER PackageList
    One or more HealOps packages to retrieve.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSModuleInfo]])]
    param(
        [Parameter(Mandatory=$false, ParameterSetName="All", HelpMessage="Indicates that all HealOps packages should be retrieved.")]
        [Switch]$All,
        [Parameter(Mandatory=$false, ParameterSetName="SpecificStringArray", HelpMessage="Indicates that the HealOps packages to retrieve are NOT the ones specified via the Package parameter.")]
        [Parameter(Mandatory=$false, ParameterSetName="SpecificList", HelpMessage="Indicates that the HealOps packages to retrieve are NOT the ones specified via the Package parameter.")]
        [Switch]$NotIn,
        [Parameter(Mandatory=$true, ParameterSetName="SpecificStringArray", HelpMessage="One or more HealOps packages to retrieve.")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Package,
        [Parameter(Mandatory=$true, ParameterSetName="SpecificList", HelpMessage="One or more HealOps packages to retrieve.")]
        [ValidateScript({$_.Count -ge 1})]
        [System.Collections.Generic.List[PSModuleInfo]]$PackageList
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Variables
        #>
        $packageList = New-Object System.Collections.Generic.List[PSModuleInfo]
        $packageSearchString = "*HealOpsPackage*"
    }
    Process {
        if ($PSCmdlet.ParameterSetName -eq 'SpecificStringArray' -or $PSCmdlet.ParameterSetName -eq 'SpecificList') {
            # Set where-object -notin or -in variable
            if ($PSCmdlet.ParameterSetName -eq 'SpecificStringArray') {
                $collection = $Package
            } else {
                $collection = $PackageList
            }

            # Retrieve specific HealOps package/s
            if ($NotIn) {
                # NotIn was used. Filter the HealOps packages retrieved
                $Packages = Get-Module -Name $packageSearchString -ListAvailable -ErrorAction Stop | Where-Object { $_.Name -notin $collection }
            } else {
                # Get the HealOps packages specified via the Package parameter
                $Packages = Get-Module -Name $packageSearchString -ListAvailable -ErrorAction Stop | Where-Object { $_.Name -in $collection }
            }
        } else {
            # Retrieve all HealOps packages
            try {
                # Get the installed HealOps packages
                $Packages = Get-Module -Name $packageSearchString -ListAvailable -ErrorAction Stop
            } catch {
                $log4netLogger.error("Getting the installed HealOps packages failed with > $_")
            }

        }

        if ($null -ne $Packages) {
            # Filter so that we end up with only 1 HealOpsPackage version per installed HealOps package.
            $filteredPackages = $Packages | Select-Object -Unique

            # Add the retrieved HealOps packages to the list
            foreach ($filteredPackage in $filteredPackages) {
                $packageList.Add($filteredPackage)
            }
        } else {
            $log4netLoggerDebug.debug("No HealOps packages found on the system. Search string > $packageSearchString")
        }
    }
    End {
        # Return
        $packageList
    }
}