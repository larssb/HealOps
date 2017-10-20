Describe "Sitecore instance healthy" {
    <#
        - Test that the Sitecore website instance is ready
    #>
    It "The Sitecore should return HTTP200" {
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

    <#
        - Test that the W3WP is not CPU exhausting the server
    #>
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

        # Find the median
        $cpuPercentageMedian = $sortedCpuPercentages.Get(5); # 29 is our median number as we are doing 59 samples.

        # Determine the result of the test
        $cpuPercentageMedian.value | Should BeLessThan 80;
    }

    <#
        - Test that there is enough diskspace left
    #>
    It "All available drives should have 10GB or more diskspace left" {
        # Get the local drives
        $localDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $null -eq $_.DisplayRoot };

        # Measure if above freespace threshold
        foreach ($drive in $localDrives) {
            $freeSpaceOkay = $drive.Free/1GB -gt 10;
        }

        # Determine the result of the test
        $freeSpaceOkay | Should Be $true;
    }

    <#
        - Test that the Octopus Deploy tentacle agent is running
    #>
    It "The Octopus Deploy tentacle agent should be running" {
        # Define general variables
        $octopusDeployTentacleURI = "https://localhost:10933/";

    $definition = @"
    using System.Collections.Generic;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;

    public static class SSLValidator
    {
        private static Stack<System.Net.Security.RemoteCertificateValidationCallback > funcs = new Stack<System.Net.Security.RemoteCertificateValidationCallback>();

        private static bool OnValidateCertificate(object sender, X509Certificate certificate, X509Chain chain,
                                                    SslPolicyErrors sslPolicyErrors)
        {
            return true;
        }

        public static void OverrideValidation()
        {
            funcs.Push(ServicePointManager.ServerCertificateValidationCallback);
            ServicePointManager.ServerCertificateValidationCallback =
                OnValidateCertificate;
        }

        public static void RestoreValidation()
        {
            if (funcs.Count > 0) {
                ServicePointManager.ServerCertificateValidationCallback = funcs.Pop();
            }
        }
    }
"@

        <#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = (New-ScriptBlockCallback -Callback {
            new-item C:\Options\test.txt;
            Set-Content C:\Options\test.txt -Value "sjovt";
         });
         #>
        #[System.Net.ServicePointManager]::ServerCertificateValidationCallback = function hej { return $true }; hej;
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = function hej { return $true }; hej;

        # Request the Octopus Deploy Tentacle endpoint
        add-type $definition;
        [SSLValidator]::OverrideValidation();
        $request = Invoke-WebRequest -Uri $octopusDeployTentacleURI -Method Get;
        [SSLValidator]::RestoreValidation();

        # Determine the result of test
        $request.StatusCode | Should Be 200;
    }
}




# Sæt til 59 samples. For ease of median picking
    ## ...så spørger vi over 5 minutter...så godt som
    ## medianen ligger så på nummer/idx 29
# Overvej rækkefølgen af testne


