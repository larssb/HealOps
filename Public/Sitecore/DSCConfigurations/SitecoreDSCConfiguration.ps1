<#
    .SYNOPSIS
        WRITE_HERE
#>
Configuration heal_sitecore {
    Import-DscResource -ModuleName SitecoreDSCResource;

    SitecoreDSCResource sitecoreInstance {
        dsSitecoreInstance = "localhost";
        Ensure = "Answering"
    }
}

# When invoking the script for compilation to MOF file.
heal_sitecore