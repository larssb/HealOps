# HealOps ReadMe

## Deploying HealOps

1 When deploying HealOps to a node you will need to deploy:

    * The specific HealOps package for the IT Service/Entity you want to monitor and heal.
    * The HealOps module itself.

## Fixing failed states based on HealOps triggered alarms.

    * Why not use the *.Tests.ps1 files, that "X" IT service/Entity is tested via, when you have had to manually remediate a failed IT service/Entity? You guessed it! That question was rhetorical. Of course you should. E.g.
        * These files are the files that will trigger the alarm again if you didn't fix the failed IT service/Entity properly.
        * They can assist you when troubleshooting.
            By:
            * Showing you what is wrong.
            * By runing them recursively after having fixed "SOMETHING" to see if that made "X" work.
## Repairing

Repairing works when:

    * There is one test in each *.Tests.ps1 file.
    * Each *.Tests.ps1 file have a matching *.Repairs.ps1 file. E.g.
        * File "F" > iisLogs.Tests.ps1 have a corresponding >
        * File "F" > iisLogs.Repairs.ps1.
    * These two files needs to be adjacent to each-other.

Rules of thumb and design of the *.Repairs.ps1 file

    * The return should always be [Boolean] $true or $false

### The *.Repairs.ps1 file

1 Is functionless

2 However still has parames.

    * An e.g.
    `
    Describe 'myPlatform.haproxy' {
        # general variables
        $URI = " URI ";

        <#
            - Test that HAProxy is up

            Runs inside Docker container
        #>
        # The HAproxy stats endpoint URI
        $haproxyStatsURI = "$URI/haproxy?stats";

        # Prep. query parameters for the call to HAProxy's stats endpoint.
        $username = " USERNAME ";
        $password = " PASSWORD ";
        $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force;
        $credential = New-Object System.Management.Automation.PSCredential($username, $secpasswd)

        try {
            # Call the HAProxy stats endpoint
            $requestResult = Invoke-WebRequest $haproxyStatsURI -Method Get -Credential $credential
        } catch {
            # TODO: LOG IT
            #$exception = $_

            # FIGURE OUT THE CAUSE AND THROW HTTP STATUS NUM.
            throw 401
        }

        It "return.http.200" {
            # Assert
            $global:assertionResult = $requestResult.StatusCode
            $requestResult.StatusCode | Should Be 200;
        }
    }
    `

## Reporting
### Alerting On-call personnel based on reports to backend report system.

    * Rule of thumb > HealOps sends data the external SaaS on-call system used. It is on that system that you configure rules for "X" IT service/Entity in regards to notify or not notify the on-call personnel. All HealOps should determine is the state of "X" IT service/Entity and if it is found to be in a failed state > try to remediate the state back to an okay state > if that fails > send a payload to the SaaS on-call management system where rules of "engagement" is defined.

### Metrics

Report data is based on metrics. Where metris is in the form e.g. ' systemName.SystemComponent.SystemSubComponent '.
#### Naming scheme

The std. is:

    * Needed values:
        * Name of the IT Service/Entity.
        * Component/part of the IT service/Entity that was tested.
        * Tags >

    * Optional is the SystemSubComponent part of metric name.

    __e.g. >__ `town1.octopusdeploy.tentacle.`

    * The above name description is to be used when defining the "Describe" keyword value in the Pester *.Tests.ps1 file. As this is where the metric name will be derived from when reporting on a metric to the backend system.

#### Metric values

    * OpenTSDB:
        * Only accepts numerical values for the metric value.

#### On state test succes

    * A global variable should be used to report the value to be used for the metric value. This global variable will be read by HealOps when reporting.
    This value needs to be a numerical type.
    * This global variable should be defined for each 'It' block in a Pester *.Tests.ps1 file.
    * The name of the global variable can only be == 'assertionResult' (without the quotes)

#### On state test failed

    *
## Setup and configuration of HealOps

1 Create a *.ps1 file

    * A good naming convention would be "healOps_"NAME_OF_SERVICE_AKA_ENTITY".ps1"
    * Call the invoke-healops function from this file.
        * With the relevant values in relation to the IT Service/Entity to invoke HealOps on.
            * Here is an example of how it could look.
            `

            `
        * Call it [n] times. One time per. IT Service/Entity you wish to validate state for.
    * Use the New-HealOpsTaks cmdlet to create a job for invoking HealOps on the IT Service/Entity
        * Refer to the file you created in step (1).

2 The HealOpsConfig.json file

    * Used for configuring an instance of HealOps.
    * Here-in you configure e.g.
        * The reporting system backend used. Possible values are so far (171030)
            * OpenTSDB