function Lock-HealOpsConfig() {
<#
.DESCRIPTION
    Tries to lock the HealOps config file via a [System.IO.File]::Open() call. Part of ensuring that only one update cycle is running in HealOps at a time.
.INPUTS
    [String] HealOpsConfigPath that represents the path to the file to lock.
.OUTPUTS
    [System.IO.FileStream] representing the file being locked and therefore ready to stream.
.NOTES
    Throws if a lock is not possible to obtain.
.EXAMPLE
    [System.IO.FileStream]$FileStream = Lock-HealOpsConfig -HealOpsConfigPath $HealOpsConfigPath
        > Calls Lock-HealOpsConfig in order to lock the HealOps config file at -HealOpsConfigPath.
.PARAMETER HealOpsConfigPath
    The path to the HealOps config file to lock.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([System.IO.FileStream])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The path to the HealOps config file to lock.")]
        [ValidateNotNullOrEmpty()]
        [String]$HealOpsConfigPath
    )

    #############
    # Execution #
    #############
    Begin {
        <#
            - Variables
        #>
        [String]$mode = "Open"
        [String]$access = "ReadWrite"
        [String]$share = "Read"
    }
    Process {
        try {
            # Lock the file.
            $file = [System.IO.File]::Open($HealOpsConfigPath, $mode, $access, $share)
        } catch [System.IO.IOException] {
            throw "The file could not be locked. Exception > $_"
        } catch {
            throw "An unexpected error occurred > $_"
        }
    }
    End {
        # Return
        $file
    }
}