# sitecoreWebsite

# Run the tests with OVF
try {
    $ovfOutput = Invoke-OperationValidation -testFilePath $PSScriptRoot\..\Diagnostics\Simple\sitecore.website.Tests.ps1;

    # Compare the two. The ovfOutput object should not hold any "FAILED" tests. That is what is being looked for.
    #$comparisonResult = Compare-Object -DifferenceObject $ovfOutput.Result -ReferenceObject $failMockComparison -IncludeEqual -ExcludeDifferent;
} catch {
    # Log
    "invoke-operationValidation failed with: $_" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

    #
    #$comparisonResult = "failed";
    $ovfOutput = "failed";
}

# Evaluate the comparison and return the result
if ($ovfOutput -ne "failed") {
    # Log
    #"comparisonResult was null" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

    #if ($ovfOutput.Result -notmatch "Failed") {
    if (-not ($ovfOutput.Result -match "Failed")) {
        $ovfOutput | select-object -Property @{N="Name";E={$_.Name}},@{N="Result";E={$_.Result}} | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        # The test did not fail == the site is alive
        return $true;
    } else {
        $ovfOutput | select-object -Property @{N="Name";E={$_.Name}},@{N="Result";E={$_.Result}} | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

        # The test failed == the site is not alive
        return $false;
    }
} else {
    # Log
    #"comparisonResult was NOT null" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;
    #"comparisonResult content > $comparisonResult" | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;
    #$ovfOutput | select-object -Property @{N="Name";E={$_.Name}},@{N="Result";E={$_.Result}} | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;

    return $false;
}