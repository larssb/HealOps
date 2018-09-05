using namespace System.Collections.Hashtable

class StatsItem : Hashtable {
    # DECLARE PROPERTIES
    [String]$Metric
    $StatsData
    hidden [Hashtable]$StatsItemContainer = @{}
    [String]$StatsOwner

    # DEFINE CONSTRUCTORS
    StatsItem([String] $Metric, [Int32] $StatsData) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [Int32]
        [ValidateNotNullOrEmpty()]
        $StatsData

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.StatsData = $StatsData

        # Declare the hashtable collection for holding the Stats item.
        $this.StatsItemContainer.Add("Metric",$Metric)
        $this.StatsItemContainer.Add("StatsData",$StatsData)
    }

    StatsItem([String] $Metric, [HashTable] $StatsData) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [HashTable]
        [ValidateNotNullOrEmpty()]
        $StatsData

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.StatsData = $StatsData

        # Declare the hashtable collection for holding the Stats item.
        $this.StatsItemContainer.Add("Metric",$Metric)
        $this.StatsItemContainer.Add("StatsData",$StatsData)
    }

    StatsItem([String] $Metric, [HashTable] $StatsData, [String] $StatsOwner) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [HashTable]
        [ValidateNotNullOrEmpty()]
        $StatsData

        [String]
        [ValidateNotNullOrEmpty()]
        $StatsOwner

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.StatsData = $StatsData
        $this.StatsOwner = $StatsOwner

        # Declare the hashtable collection for holding the Stats item.
        $this.StatsItemContainer.Add("Metric",$Metric)
        $this.StatsItemContainer.Add("StatsData",$StatsData)
        $this.StatsItemContainer.Add("StatsOwner",$StatsOwner)
    }
}