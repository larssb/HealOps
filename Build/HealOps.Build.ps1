param(
    $BuildType = (property BuildType)
)
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
$BuildOutputRoot = "$BuildRoot/BuildOutput/$ModuleName"

# Determine run mode
$runmode = [Environment]::UserInteractive
###############
#### TASKS ####
###############
<#
    - The below task will be the default build task in the Invoke-Build New-VSCodeTask.ps1 script generated VS Code tasks.json file.
    Simply because it is the first declared task in this build file.
#>
task Build {
    $folderToInclude = @('Artefacts','Private','Public')

    # Ensure proper state of the build output folder
    if(-not (Test-Path -Path $BuildOutputRoot)) {
        # Create the dir
        New-Item -Path $BuildOutputRoot -ItemType Directory | Out-Null
    } else {
        # clean the dir
        try {
            Remove-Item -Path $BuildOutputRoot -Recurse -Force
        } catch {
            $_
        }
    }

    # Copy folders to BuildOutputRoot
    ForEach ($folder in $folderToInclude) {
        Write-Verbose "Folder info: $ModuleRoot$folder"
        Copy-item -Recurse -Path $ModuleRoot$folder -Destination $BuildOutputRoot/$folder
    }

    # Copy relevant files from the module root
    Get-ChildItem -Path $ModuleRoot\* -File -Exclude "*.gitignore","mkdocs.yml" | Copy-Item -Destination $BuildOutputRoot

    # Compile the HealOps dll
    Push-Location -Path $ModuleRoot/src -StackName "Build"
    try {
        dotnet build --output $BuildOutputRoot/bin
    } finally {
        Pop-Location -StackName "Build"
    }

    # Get the version set by the semver ConcourseCI resource. The version variable
    # needs to be in the "Script" scope in order to be getable by other tasks
    # that requires it.
    if($BuildType -ne "ConcourseCI") {
        [String]$Script:Version = "100.100.100"
    } else {
        [String]$Script:Version = Get-Content -Path /version
    }
    Write-Build Green "Version is: $Version"

    # Update the version in the manifest
    Update-ModuleManifest -Path $BuildOutputRoot/HealOps.psd1 -ModuleVersion $Version

    <#
        - Give build information on where to find the cooked package
    #>
    if($runmode -eq $true) {
        Write-Build Green "The build completed and its output can be found in: $BuildOutputRoot"
    }
}

<#
    - Cleans up after running InvokeBuild. Should always run. Therefore the usage of Exit-Build.
#>
<# Exit-Build {

} #>

<#
    - Install the module on the system where
#>
task "Install-PS-Module" {
    # Get the version to install the module underneath the correct folder.
    write-build green "Input version is: $Version"
}

task Publish {
    # Publish the module
    Publish-Module -Name $BuildOutputRoot -Repository HealOps -NuGetApiKey "" -ErrorAction Stop
}

task RunAllTests {
    # First import the Pester Tests Settings module
    Import-Module -Name $PSScriptRoot/../Tests/Pester.Tests.Settings.psm1 -Force

    # Execute the tests
    $PesterRunResult = Invoke-Pester $PSScriptRoot/../Tests/CentralBuildLevel -PassThru -Show Failed -Strict

    # Evaluate the result of running the tests.
    Assert ( $PesterRunResult.FailedCount -eq 0 ) "All tests should succeed. There was this number > $($PesterRunResult.FailedCount) < of failed Pester tests."
}

task "Publish-Build" -Jobs Build, "Install-PS-Module", RunAllTests, Publish
task "Build-Test" -Jobs Build, RunAllTests