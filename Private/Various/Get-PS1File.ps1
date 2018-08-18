function Get-PS1File() {
<#
.DESCRIPTION
    Get-PS1File can be used to find a PS1 file in a PowerShell module. It will look into the newest version of the module.
.INPUTS
    [String]FileName. The name of the PS1 file to find in the module.
    [String]ModuleName. The name of the module wherein the function should look for the file.
.OUTPUTS
    [System.IO.FileSystemInfo]File. If a file is found.
.NOTES
    <none>
.EXAMPLE
    PS C:\> $File = Get-PS1File -FileName MyFile -ModuleName MyModule
    Executes Get-PS1File which will try to find the file named "MyFile" in the module "MyModule. The file is "saved" to the
.PARAMETER FileName
    The name of the PS1 file to find in the module named as specified via the ModuleName parameter.
.PARAMETER ModuleName
    The name of the module wherein the function should look for a file named as FileName.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([System.IO.FileSystemInfo])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$FileName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$ModuleName
    )

    #############
    # Execution #
    #############
    Begin {
        # Control if the value of $FileName include the proper extension. To support specifying the FileName to find with or without an extension.
        $FileNameExt = [System.IO.Path]::GetExtension($FileName)
        if (-not ($FileNameExt -match ".ps1") ) {
            $FileName = "$FileName.ps1"
        }
    }
    Process {
        # Get the latest version of the specified PowerShell module.
        try {
            $LatestModule = Get-LatestModuleVersionLocally -ModuleName $ModuleName -ErrorAction Stop
        } catch {
            $Message = "Getting the latest version of the module named $ModuleName failed with $($_ | Out-String)"

            # Log it
            $log4netLogger.error("$message")

            # Exit
            throw $message
        }

        # Try to get a file named as specified via the $FileName parameter.
        try {
            $File = Get-ChildItem -Path $LatestModule.ModuleBase -Include $FileName -Recurse -ErrorAction Stop
        } catch {
            $message = "Getting the file named $FileName in the module named $ModuleName failed with > $($_ | Out-String)"

            # Log it
            $log4netLogger.error("$message")

            # Exit
            throw $message
        }

        # Control that the File was found
        if ($null -eq $File) {
            $message = "No file named $FileName was found."

            # Log it
            $log4netLogger.error("$message")

            # Exit
            throw $message
        }
    }
    End {
        # Return
        $File
    }
}