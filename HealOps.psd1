@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HealOps.psm1'

    # Version number of this module.
    ModuleVersion = '1.2.1'

    # ID used to uniquely identify this module
    GUID = 'a7de9802-3086-4612-a31f-8da988c2eca0'

    # Author of this module
    Author = 'Lars S. Bengtsson | https://github.com/larssb | https://bengtssondd.it'

    # Company or vendor of this module
    CompanyName = 'Bengtsson Driven Development'

    # Copyright statement for this module
    Copyright = '(C) Lars S. Bengtsson (https://github.com/larssb), licensed under the MIT License.'

    # Description of the functionality provided by this module
    Description = 'HealOps is a state monitoring and broken state repairing framework. Use it for all your operation validation needs. Automatically monitor and
    repair the state of IT systems and their components. Systems and components can be monitored by writing Pester tests that acts as the state determining engine.
    Regular PowerShell scripts are used for repairing a broken state of a system or component. Furthermore, HealOps can also be used to collect stats.
    This also happens via PowerShell scripts.'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'Pester'; ModuleVersion = '4.1.0'; },
        @{ModuleName = 'PowerShellTooling'; ModuleVersion = '1.0.2'; }
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @('bin\HealOps.dll')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Install-HealOpsPackage'
        'Invoke-HealOps'
        'Out-MetricsCollectionObject'
        'Out-MetricItemObject'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @(
                'HealOps'
                'Monitoring'
                'Healing'
                'Incident management'
                'TDD'
                'Test driven development'
                'Pester'
            )

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/larssb/HealOps/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/larssb/HealOps'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Making it possible to validate config files needed with HealOps. Via a JSONSchema and a validator function.'

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $False

            # External dependent modules of this module
            # ExternalModuleDependencies = ''

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}