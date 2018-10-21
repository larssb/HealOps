<#
    A mock object creator to have a proper object to give to Read-EntityState.
#>
# Initiate a collection to hold stats data.
$MetricsCollection = Out-MetricsCollectionObject

# Get a MetricItem object and populate its properties
$MetricItem = Out-MetricItemObject
$MetricItem.Metric = "dummy.name.tests"
$MetricItem.MetricData = @{
    "Value" = "This.Is.A.Test"
}

# Add the result to the Stats collection.
$MetricsCollection.Add($MetricItem)

# Return the gathered stats to caller.
,$MetricsCollection