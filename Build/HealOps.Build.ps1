#requires -modules PowerShellTooling

param(
    $BuildType = (property BuildType Direct),
    $PublishType = (property PublishType Internal),
    $PublishSecret = (property PublishSecret)
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
# Get the version set by the semver ConcourseCI resource. The version variable
# needs to be in the "Script" scope in order to be getable by other tasks
# that requires it.
if($BuildType -ne "ConcourseCI") {
    [String]$Script:Version = "100.100.100"
} else {
    [String]$Script:Version = Get-Content -Path /version
}

# Set shared build metadata variables
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
    # Ensure proper state of the build output folder
    if(-not (Test-Path -Path $BuildOutputRoot)) {
        # Create the dir
        New-Item -Path $BuildOutputRoot -ItemType Directory | Out-Null
    } else {
        # Clean the dir
        try {
            Remove-Item -Path $BuildOutputRoot -Recurse -Force
        } catch {
            throw $_
        }
    }

    # Copy folders to BuildOutputRoot
    $folderToInclude = @('Artefacts','Private','Public')
    ForEach ($folder in $folderToInclude) {
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

    # Update the version in the manifest
    Update-ModuleManifest -Path $BuildOutputRoot/$ModuleName.psd1 -ModuleVersion $Version

    # Create a version folder
    $VersionDir = New-Item -Path $BuildOutputRoot -ItemType Directory -Name $Version

    # Move files from the BuildOutputRoot to the version folder
    Move-Item -Path $BuildOutputRoot/* -Destination $VersionDir -Force -Exclude "$Version" | Out-Null

    <#
        - Give build information on where to find the cooked package
    #>
    if($runmode -eq $true) {
        Write-Build Green "The build completed and its output can be found in: $BuildOutputRoot"
    }
}, "Install-PS-Module"

<#
    - Cleans up after running InvokeBuild. Should only run if not run inside a ConcourseCI worker container.
    If it is, we don't care, as the container is ephemeral and will be destroyed.
#>
Exit-Build {
    If($BuildType -ne "ConcourseCI") {
        # Delete the module files copied to the user PS modules folder
        try {
            Remove-Item -Path $PSModulesPath/$ModuleName -Recurse -Force -ErrorAction Stop
        } catch {
            throw "Cleanup failed. Removing the module build from the user context PS modules dir failed with: $_"
        }
    }
}

<#
    - The module is installed underneath the version defined in $Version.
    > It has to be installed on the system to properly test that the module works
    in a production like execution environment.
#>
task "Install-PS-Module" {
    # Get root of installation
    $Script:PSModulesPath = Get-PSModulesPath -Level User

    # Copy the output from the "Build" task >> to the $PSModulesPath/$ModuleName/$Version folder
    Copy-Item -Path $BuildOutputRoot -Destination $PSModulesPath -Recurse -Force
}

task Publish {
    # Define the package management repository to use for the publish
    if ($PublishType -eq "Internal") {
        #
        # Use an internal repository, if eyeball testing is wanted (TEST)
        #
        [String]$RepositoryName = "nexusIbigPSGallery"

        # Ensure that the repository is available
        if (-not (Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue)) {
            Register-PSRepository -Name $RepositoryName -SourceLocation "http://192.168.0.20/nexus/repository/ibigPSGallery/" `
            -PublishLocation "http://192.168.0.20/nexus/repository/ibigPSGallery/" -ScriptPublishLocation "http://192.168.0.20/nexus/repository/ibigPSGallery/" `
            -ScriptSourceLocation "http://192.168.0.20/nexus/repository/ibigPSGallery/" -InstallationPolicy Trusted -PackageManagementProvider NuGet
        }

        Publish-Module -Name $BuildOutputRoot -Repository $RepositoryName -Credential
    } else {
        # Use the PowerShellGallery as the endpoint for publishing the module (PROD)
        [String]$RepositoryName = "PSGallery"
    } else {
        # Publish the module
        Publish-Module -Name $BuildOutputRoot -Repository $RepositoryName -NuGetApiKey $PublishApiKey -ErrorAction Stop
    }
}

task RunAllTests {
    # First import the Pester Tests Settings module
    Import-Module -Name $PSScriptRoot/../Tests/Pester.Tests.Settings.psm1 -Force -ArgumentList $Version

    # Execute the tests
    $PesterRunResult = Invoke-Pester $PSScriptRoot/../Tests/CentralBuildLevel -PassThru -Show Failed, Summary -Strict

    # Evaluate the result of running the tests.
    Assert ( $PesterRunResult.FailedCount -eq 0 ) "All tests should succeed. There was this number > $($PesterRunResult.FailedCount) < of failed Pester tests."
}

#task "Publish-Build" -Jobs Build, "Install-PS-Module", RunAllTests, Publish, CleanUp
task "Publish-Build" -Jobs Build, RunAllTests, Publish #, CleanUp
task "Build-Test" -Jobs Build, RunAllTests, CleanUp