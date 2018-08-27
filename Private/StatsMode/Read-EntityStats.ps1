function Read-EntityStats() {
<#
.DESCRIPTION
    A wrapper function. Standardizing the execution of a *.Stats.ps1 file.
.INPUTS
    [String]StatsFilePath. Representing the path to a *.Stats.ps1 file.
.OUTPUTS
    Stats
.NOTES
    <none>
.EXAMPLE
    PS C:\> $Stats = Read-EntityStats -StatsFilePath ./PATH/ENTITY_TO_GATHER_STATS_ON.Stats.ps1
    Calls Read-EntityStats which will execute the *.Stats.ps1 file provided via the StatsFilePath parameter.
.PARAMETER StatsFilePath
    The full path to a *.Stats.ps1 file. By executing the *.Stats.ps1 file stats will be gathered on an IT system/component.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$StatsFilePath
    )

    #############
    # Execution #
    #############
    Begin {
        # Determine the file name of the Stats file. Used for logs entries and the like.
        [String]$StatsFileBaseName = ($StatsFilePath -split "\\")[-1]
        Write-Verbose -Message "The name of the Statsfile is determind to be > $StatsFileBaseName."
    }
    Process {
        if (Test-Path -Path $StatsFilePath) {
            # Run the Stats file.
            try {
                if ($PSBoundParameters.ContainsKey('Verbose')) {
                    $Stats = . $StatsFilePath -Verbose
                } else {
                    $Stats = . $StatsFilePath
                }
            } catch {
                throw "Read-EntityStats | Gathering stats via the following stats file > $StatsFileBaseName failed with > $_"
            }
        } else {
            $log4netLogger.error("Read-EntityStats | The stats file $StatsFileBaseName could not be found.")
            throw "Read-EntityStats | The stats file $StatsFileBaseName could not be found.";
        }
    }
    End {
        # Define the stats hashtable collection (make it ready for reporting).
        $TempCollection = @{}
        $TempCollection.Add("StatsData",$Stats)
        $TempCollection.Add("Metric",$($))

        # Return the stats.
        $Stats
    }
}