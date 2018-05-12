###########################
# Set variables to export #
###########################
# Temp. helper variable
$ModulePath = "$PSScriptRoot/.."

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$Settings = @{
    moduleName = Get-Item $ModulePath/*.psd1 | Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } | Select-Object -First 1 | Foreach-Object BaseName
    moduleRoot = Resolve-Path $ModulePath
    PesterSettingsModuleName = "Pester.Tests.Settings"
}

############################
# Find functions to export #
############################
# Define the foldernames from which to fetch functions to export
$functionFolders = @('Public', 'Private')

# Run over each folder and look for files to include/inject into the PSD1 manifest file
ForEach ($folder in $functionFolders) {
    $folderPath = Join-Path -Path $Settings.moduleRoot -ChildPath $folder

    If (Test-Path -Path $folderPath) {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse;

        ForEach ($function in $functions) {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $($function.FullName)
        }
    }
}

# The public functions to export
$publicFunctions = (Get-ChildItem -Path "$($Settings.moduleRoot)\Public" -Filter '*.ps1' -Recurse).BaseName

<#
    - The private functions to export. Exported in order to be able to run Pester over the private functions. Not using Pesters
    'InModuleScope' feature as the purpose is to use this module as the bootstrapper for Pester tests. Enabling us to import the
    module being tested only once.
#>
$privateFunctions = (Get-ChildItem -Path "$($Settings.moduleRoot)\Private" -Filter '*.ps1' -Recurse).BaseName

# Add the function arrays together
$functions = $publicFunctions += $privateFunctions

##########
# Export #
##########
Export-ModuleMember -Variable Settings -Function $functions