using namespace System.Collections.Hashtable

class MetricItem : Hashtable {
    # DECLARE PROPERTIES
    [String]$Metric
    $MetricData
    hidden [Hashtable]$MetricItemContainer = @{}
    [String]$StatsOwner

    # DEFINE CONSTRUCTORS
    MetricItem([String] $Metric, [Int32] $MetricData) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [Int32]
        [ValidateNotNullOrEmpty()]
        $MetricData

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.MetricData = $MetricData

        # Declare the hashtable collection for holding the Stats item.
        $this.MetricItemContainer.Add("Metric",$Metric)
        $this.MetricItemContainer.Add("MetricData",$MetricData)
    }

    MetricItem([String] $Metric, [HashTable] $MetricData) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [HashTable]
        [ValidateNotNullOrEmpty()]
        $MetricData

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.MetricData = $MetricData
        [Int32]$this.MetricData.Value = 0

        # Declare the hashtable collection for holding the Stats item.
        $this.MetricItemContainer.Add("Metric",$Metric)
        $this.MetricItemContainer.Add("MetricData",$MetricData)
    }

    MetricItem([String] $Metric, [HashTable] $MetricData, [String] $StatsOwner) {
        [String]
        [ValidateNotNullOrEmpty()]
        $Metric

        [HashTable]
        [ValidateNotNullOrEmpty()]
        $MetricData

        [String]
        [ValidateNotNullOrEmpty()]
        $StatsOwner

        # Set the properties, to the incoming values
        $this.Metric = $Metric
        $this.MetricData = $MetricData
        [Int32]$this.MetricData.Value = 0
        $this.StatsOwner = $StatsOwner

        # Declare the hashtable collection for holding the Stats item.
        $this.MetricItemContainer.Add("Metric",$Metric)
        $this.MetricItemContainer.Add("MetricData",$MetricData)
        $this.MetricItemContainer.Add("StatsOwner",$StatsOwner)
    }
}