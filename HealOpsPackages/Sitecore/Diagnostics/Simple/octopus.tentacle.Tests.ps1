Describe "The Octopus Deploy tentacle is alive" {
    <#
        - Test that the Octopus Deploy tentacle agent is running
    #>
    It "The Octopus Deploy tentacle agent should be running" {
        # Define general variables
        $octopusDeployTentacleURI = "https://localhost:10933/";

        # Create .NET object for self-signed cert. handling.
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

        # Request the Octopus Deploy Tentacle endpoint
        add-type $definition;
        [SSLValidator]::OverrideValidation();

        try {
            $request = Invoke-WebRequest -Uri $octopusDeployTentacleURI -Method Get -UseBasicParsing;
        } catch {
            "The Octopus Deploy webrequest call falied. The error was > $_ " | Add-Content -Path $PSScriptRoot\log.txt -Encoding UTF8;
        }

        [SSLValidator]::RestoreValidation();

        # Determine the result of test
        $request.StatusCode | Should Be 200;
    }
}