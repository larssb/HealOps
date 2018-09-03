function Read-EntityStats() {
<#
.DESCRIPTION
    A wrapper function. Formalizing the execution of a *.Stats.ps1 file.
.INPUTS
    [String]StatsFilePath. Representing the path to a *.Stats.ps1 file.
.OUTPUTS
    A [System.Collections.Generic.List`1[StatsItem]] type collection, containing the [StatsItem]'s. The [StatsItem] collection is generated by the executed Stats file.
.NOTES
    Set to output [Void] in order to comply with the PowerShell language. Also if [Void] wasn't used, an error would be thrown when invoking the function.
    As the output type [System.Collections.Generic.List`1[StatsItem]] would not be known by PowerShell, when this function is invocated.
.EXAMPLE
    PS C:\> $Stats = Read-EntityStats -StatsFilePath ./PATH/ENTITY_TO_GATHER_STATS_ON.Stats.ps1
    Read-EntityStats will execute the *.Stats.ps1 file, specified via the StatsFilePath parameter.
.PARAMETER StatsFilePath
    The full path to a *.Stats.ps1 file. By executing the *.Stats.ps1 file stats will be gathered on an IT system/component.
#>

    # Define parameters
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Void])]
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
        <#
            Sanity tests/validation controls on the Stats object retrieved from executing the StatsFile on the StatsFilePath.
        #>
        [String]$ExceptionMessage = "The Stats data returned from the $StatsFileBaseName cannot be supported by HealOps."

        if (-not ($Stats.GetType().FullName -match "StatsItem")) {
            [String]$StatsType_Exception = "$ExceptionMessage The stats collection does not match a strongly typed collection for >> [StatsItem]."
            Write-Verbose -Message $StatsType_Exception
            throw $StatsType_Exception
        }

        if (-not ($Stats.Count -gt 0)) {
            [String]$StatsCount_Exception = "$ExceptionMessage There is no items in the Stats collection."
            Write-Verbose -Message $StatsCount_Exception
            throw $StatsCount_Exception
        }

        #$enumerator = $Stats.GetEnumerator()
        foreach ($item in $Stats) {
            if (-not ($item.GetType().Name -eq "StatsItem")) {
                [String]$ItemControl_Exception = "$ExceptionMessage An item in the Stats collection is not of the correct type ([StatsItem])."
                Write-Verbose -Message $ItemControlException
                throw $ItemControl_Exception
            }
        }

        # Return the stats.
        $Stats
    }
}