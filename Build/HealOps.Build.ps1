#Requires -Modules powershellTooling
###############
#### PREP. ####
###############
# Include: Settings
#. "$PSScriptRoot/settings.Build.ps1"

# Include: build utils
Import-Module -Name powerShellTooling -Force
. "$PSScriptRoot/utils.Build.ps1"

<#
    - Shared InvokeBuild settings and prep.
#>
$ModuleRoot = "$BuildRoot/../"
$ModuleName = (Get-Item -Path $ModuleRoot* -Include *.psm1).BaseName
$buildOutputRoot = "$BuildRoot/BuildOutput/$ModuleName/"

# Handle the buildroot folder
if(-not (Test-Path -Path $buildOutputRoot)) {
    # Create the dir
    New-Item -Path $buildOutputRoot -ItemType Directory | Out-Null
} else {
    # clean the dir
    try {
        Remove-Item -Path $buildOutputRoot -Recurse -Force
    } catch {
        $_
    }
}

###############
#### TASKS ####
###############
<#
    - Main build task
#>
$folderToInclude = @('Artefacts','docs','Private','Public')

task build {
    # Copy folders to buildOutputRoot
    ForEach ($folder in $folderToInclude) {
        Write-Verbose "Folder info: $ModuleRoot$folder"
        Copy-item -Recurse -Path $ModuleRoot$folder -Destination $buildOutputRoot/$folder
    }

    # Copy relevant files from the module root
    Get-ChildItem -Path $ModuleRoot\* -File -Exclude "*.gitignore" | Copy-Item -Destination $buildOutputRoot

    <#
        - Give build information on where to find the cooked package
    #>
    if((test-powershellRunMode -Interactive) -eq $true) {
        Write-Build Green "The build completed and its output can be found in: $buildOutputRoot"
    }
}