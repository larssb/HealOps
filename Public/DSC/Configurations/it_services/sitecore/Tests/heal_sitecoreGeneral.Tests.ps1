Describe "Sitecore instance healthy" {
    It "The Sitecore website returns HTTP200" {
        <#
            - Set webrequest variables

            N.b. the below endpoint tests the following:
                1. that the mongodb backend is up
                2. that the MSSQL backend is up
                3. Implicitly that the IIS website is up and running.
                    3a. Thereby implicitly that the app. pool for the website is running.
        #>
        $uri = "http://localhost:8080/Components/Common/Framework/Healthcheck/Presentation/SystemDiagnostics.aspx"

        # request the endpoint
        try {
            $webReq = Invoke-WebRequest -Uri $uri -Method Get;
        } catch {
            $webReq = "requestFailed";
        }

        # Determine the result of the test
        $webReq.StatusCode | Should be "200";
    }

    It "W3WP IIS process usage should be below 80% over a 5minute period" {
        # Do the measurement
        $cpuPercentMeasures = Get-Counter -ComputerName localhost -Counter '\Process(w3wp)\% Processor Time' -MaxSamples 10 -SampleInterval 1 `
        | Select-Object -ExpandProperty countersamples `
        | Select-Object -Property instancename,@{L='CPU';E={($_.Cookedvalue/100).toString('P')}}

        # Collection for containing sorted CPU percentage measures
        $cpuPercentages = @{};
        foreach ($measure in $cpuPercentMeasures) {
            # Remove "%" from the output
            [float]$cpuPercentage = $measure.cpu -replace "%","" -replace ",",".";

            # Add the CPU percentage to a collection for sorting
            $randomKey = Get-Random;
            $cpuPercentages.Add($randomKey,$cpuPercentage);
        }

        # Sort the collection
        $cpuPercentagesEnumerator = $cpuPercentages.GetEnumerator();
        $sortedCpuPercentages = $cpuPercentagesEnumerator | Sort-Object Value;

        write-host "Just checking > $($sortedCpuPercentages.value)"

        # Find the median
        $cpuPercentageMedian = $sortedCpuPercentages.Get(5); # 29 is our median number as we are doing 59 samples.

        # Determine the result of the test
        $cpuPercentageMedian.value | Should BeLessThan 80;
    }
}



# Sæt til 59 samples. For ease of median picking
    ## ...så spørger vi over 5 minutter...så godt som
    ## medianen ligger så på nummer/idx 29
# Overvej rækkefølgen af testne


