<<<<<<< HEAD
<#
    .SYNOPSIS
        Composite configuration to be used when controlling Windows processes.
#>
Configuration composite_win_process {
    param (
        # The name of the process to control
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processArgs
    )

        # Import the module/s that defines custom resources
        Import-DscResource -ModuleName xPSDesiredStateConfiguration

        <#
            - Control the process
        #>
        Node localhost {
            xWindowsProcess $processName {
                Arguments = $processArgs
                Path = $processPath
                Ensure = "Present"
            }
        }
=======
<#
    .SYNOPSIS
        Composite configuration to be used when controlling Windows processes.
#>
Configuration composite_win_process {
    param (
        # The name of the process to control
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$processArgs
    )

        # Import the module/s that defines custom resources
        Import-DscResource -ModuleName xPSDesiredStateConfiguration

        <#
            - Control the process
        #>
        Node localhost {
            xWindowsProcess $processName {
                Arguments = $processArgs
                Path = $processPath
                Ensure = "Present"
            }
        }
>>>>>>> 6bff47c62854fcd4620ce3f5e7d29cafae108b52
}