Describe "The Sitecore instance is alive" {
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
            $webReq = Invoke-WebRequest -Uri $uri -Method Get -UseBasicParsing;
        } catch {
            $webReq = "requestFailed";

            "The error was > $_ " | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;
        }

        # Determine the result of the test
        $webReq.StatusCode | Should be "200";
    }
}