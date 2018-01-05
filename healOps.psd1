@{
# Script module or binary module file associated with this manifest.
RootModule = 'HealOps'

# Version number of this module.
ModuleVersion = '0.0.0.47'

# ID used to uniquely identify this module
GUID = 'a7de9802-3086-4612-a31f-8da988c2eca0'

# Author of this module
Author = 'Labe | labe@danskespil.dk'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2017 Labe | labe@danskespil.dk. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A self-healing monitoring system. Uses Pester tests (TDD) to determine the state of a system entity. Then, if the entity is in a faulted state HealOps will try to repair it. All along HealOps reports metrics to a backend report system and HealOps status is sent to stakeholders. In order to e.g. trigger alarms and get on-call personnel on an issue that could not be repaired.'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'Pester'; ModuleVersion = '4.1.0'; },
                @{ModuleName = 'powerShellTooling'; ModuleVersion = '0.0.0.8'; })

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Invoke-HealOps')

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