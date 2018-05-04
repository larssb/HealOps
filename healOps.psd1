@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'HealOps.psm1'

    # Version number of this module.
    ModuleVersion = '0.0.0.51'

    # ID used to uniquely identify this module
    GUID = 'a7de9802-3086-4612-a31f-8da988c2eca0'

    # Author of this module
    Author = 'Lars S. Bengtsson | https://github.com/larssb | https://bengtssondd.it'

    # Company or vendor of this module
    CompanyName = 'Bengtsson Driven Development'

    # Copyright statement for this module
    Copyright = '(C) 2018, Lars S. Bengtsson. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A self-healing monitoring system. Uses Pester tests (TDD) to determine the state of a system entity. Then, if the entity is in a faulted state HealOps will try to repair it. All along HealOps reports metrics to a backend report system and HealOps status is sent to stakeholders. In order to e.g. trigger alarms and get on-call personnel on an issue that could not be repaired.'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(@{ModuleName = 'Pester'; ModuleVersion = '4.1.0'; },
                        @{ModuleName = 'PowerShellTooling'; ModuleVersion = '0.0.12'; })

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Invoke-HealOps'
        'Install-HealOpsPackage'
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
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = False

            # External dependent modules of this module
            # ExternalModuleDependencies = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}