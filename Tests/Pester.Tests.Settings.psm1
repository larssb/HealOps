###########################
# Set variables to export #
###########################
# Temp. helper variable
$ModulePath = "$PSScriptRoot/.."

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Settings = @{
    ModuleName = Get-Item $ModulePath/*.psd1 | Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } | Select-Object -First 1 | Foreach-Object BaseName
    ModuleRoot = Resolve-Path $ModulePath
    PesterSettingsModuleName = "Pester.Tests.Settings"
}

# PowerShell below 5 is not module versioning compatible. Reflect this.
if($PSVersionTable.PSVersion.ToString() -gt 4) {
    [Boolean]$global:PSVersionAbove4 = $true
} else {
    [Boolean]$global:PSVersionAbove4 = $false
}

############################
# Find functions to export #
############################
# Define the foldernames from which to fetch functions to export
$FunctionFolders = @('Public', 'Private')

# Run over each folder and look for files to include/inject into the PSD1 manifest file
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $Settings.moduleRoot -ChildPath $folder

    If (Test-Path -Path $folderPath) {
        Write-Verbose -Message "Importing from $folder"
        $Functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse;

        ForEach ($Function in $Functions) {
            Write-Verbose -Message "  Importing $($Function.BaseName)"
            . $($Function.FullName)
        }
    }
}

# The public functions to export
$PublicFunctions = (Get-ChildItem -Path "$($Settings.ModuleRoot)\Public" -Filter '*.ps1' -Recurse).BaseName

<#
    - The private functions to export. Exported in order to be able to run Pester over the private functions. Not using Pesters
    'InModuleScope' feature as the purpose is to use this module as the bootstrapper for Pester tests. Enabling us to import the
    module being tested only once.
#>
$PrivateFunctions = (Get-ChildItem -Path "$($Settings.ModuleRoot)\Private" -Filter '*.ps1' -Recurse).BaseName

# Add the function arrays together
$Functions = $PublicFunctions += $PrivateFunctions

##########
# Export #
##########
Export-ModuleMember -Variable Settings -Function $Functions