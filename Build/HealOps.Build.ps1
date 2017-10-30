###############
#### PREP. ####
###############
# Include: Settings
. "$PSScriptRoot/settings.Build.ps1"

# Include: build utils
. "$PSScriptRoot/utils.Build.ps1"

<#
    - Shared InvokeBuild settings and prep.
#>
$ModuleName = (Get-Item -Path $PSScriptRoot/../* -Include *.psm1).BaseName
$buildRoot = "$PSScriptRoot/BuildOutput/$ModuleName"

# Handle the buildroot folder
if(-not (Test-Path -Path $buildRoot)) {
    # Create the dir
    New-Item -Path $buildRoot -ItemType Directory
} else {
    # clean the dir
    Remove-Item -Path $buildRoot\* -Recurse -Force
}


###############
#### TASKS ####
###############
<#
    - Main build task
#>
$folderToInclude = @('Artefacts','docs','Private','Public')

task build {
    # Copy folders to the buildroot
    ForEach ($folder in $folderToInclude) {

    }

    # Copy relevant files from the module root
    Copy-Item -Path $PSScriptRoot/../ -Exclude ".gitignore" -Destination $buildRoot

    # Give information on where to find the cooked package

}