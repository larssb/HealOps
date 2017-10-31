###############
#### PREP. ####
###############
# Module import
Import-Module -name powerShellTooling

# Include: Settings
#. "$PSScriptRoot/settings.Build.ps1"

# Include: build utils
#. "$PSScriptRoot/utils.Build.ps1"

<#
    - Shared InvokeBuild settings and prep.
#>
$ModuleRoot = "$BuildRoot/../"
$ModuleName = (Get-Item -Path $ModuleRoot* -Include *.psm1).BaseName
$buildOutputRoot = "$BuildRoot/BuildOutput/$ModuleName/"

# Handle the buildroot folder
if(-not (Test-Path -Path $buildOutputRoot)) {
    # Create the dir
    New-Item -Path $buildOutputRoot -ItemType Directory
} else {
    # clean the dir
    try {
        Remove-Item -Path $buildOutputRoot -Recurse -Force -Verbose
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
$folderToInclude = @('docs','Private','Public')

task build {
    # Copy folders to buildOutputRoot
    ForEach ($folder in $folderToInclude) {
        Copy-item -Recurse -Path $ModuleRoot$folder -Destination $buildOutputRoot
    }

    # Copy relevant files from the module root
    Get-ChildItem -Path $ModuleRoot -File | Copy-Item -Destination $buildOutputRoot

    <#
        - Give build information on where to find the cooked package
    #>
    if((test-powershellRunMode) -eq "interactive") {
        Write-Build Green "The build completed and its output can be found in: $buildOutputRoot"
    }
}