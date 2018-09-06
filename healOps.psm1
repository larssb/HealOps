<#
    - Import classes
#>
. $PSScriptRoot/Private/MetricsSystem/MetricItem.Class.ps1

<#
    - Determine system specific values
#>
# PowerShell below 5 is not module versioning compatible. Reflect this.
if($PSVersionTable.PSVersion.ToString() -gt 4) {
    [Boolean]$global:psVersionAbove4 = $true
} else {
    [Boolean]$global:psVersionAbove4 = $false
}

# RunMode global variable
[Boolean]$global:runMode = test-powershellRunMode -Interactive

# Define the foldernames
$functionFolders = @('Public', 'Private')

# Run over each folder and look for files to include/inject into the PSD1 manifest file
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder

    If (Test-Path -Path $folderPath) {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse;

        ForEach ($function in $functions) {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1' -Recurse).BaseName

# Export the public functions
Export-ModuleMember -Function $publicFunctions