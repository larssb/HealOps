###############
#### PREP. ####
###############
# Include: Settings
#. "$PSScriptRoot/settings.Build.ps1"

# Include: build utils
. "$PSScriptRoot/utils.Build.ps1"

<#
    - Shared InvokeBuild settings and prep.
#>
$ModuleRoot = "$BuildRoot/../"
$ModuleName = (Get-Item -Path $ModuleRoot* -Include *.psm1).BaseName
$buildOutputRoot = "$BuildRoot/BuildOutput/$ModuleName"

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

# Determine run mode
$runmode = [Environment]::UserInteractive
###############
#### TASKS ####
###############
<#
    - The below task will be the default build task in the Invoke-Build New-VSCodeTask.ps1 script generated VS Code tasks.json file.
    Simply because it is the first declared task in this build file.
#>
$folderToInclude = @('Artefacts','docs','Private','Public')
task Build {
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
    if($runmode -eq $true) {
        Write-Build Green "The build completed and its output can be found in: $buildOutputRoot"
    }
}

task Publish {
    # Publish the module
    Publish-Module -Name $buildOutputRoot -Repository HealOps -NuGetApiKey "" -ErrorAction Stop
}

task RunAllTests {
    # First import the Pester Tests Settings module
    Import-Module -Name $PSScriptRoot/../Tests/Pester.Tests.Settings.psm1 -Force

    # Execute the tests
    Invoke-Pester $PSScriptRoot/../Tests/
}

task RunConfigurationManagementTests {
    #
}

task BuildPublish Build, Publish