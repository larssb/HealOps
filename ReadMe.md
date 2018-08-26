# Synopsis

I (Lars Bengtsson) started developing HealOps in early 2017. From the ideas and thoughts that it had to be possible to make life as a DevOps Engineer and as a member of the on-call team at work easier. By:

- Improving the info received when getting a call when on on-call duty.
- Even better, developing a system that tries healing 'x' IT component and if that succeeds I can continue my sleep unknowingly of the mishap.
    - Although it will be possible to see that this happened, as the issue is logged.
- Having the system automatically contact the person on on-call duty, instead of having manual labour doing this. Because, having manual labor doing this.
    - The person/persons alerting an on-call duty person, often does not have the info and even sometimes the necessary skillset required to manage what 'x' component being in a bad state really means for 'x' system.
    - Has so far been my experience that this slows the mean time to response.
    - The number of incorrect call-ups is too high.
- Automatizing the monitoring, healing and alerting of IT services and its components.
- By making it possible to query the health of IT services and its components over time and thereby making available, to a higher degree of likeliness, the support of informed decisions that are based on data.
- Present and visualize data via dashboard systems.
- Packaging the code needed to monitor and healing 'x' IT service and its components into clearly compartmentalized entities. That makes it possible to:
    - Deploy those easily.
    - Modularize these packages, which then makes it easier to re-use them for different IT service monitoring and healing situations.

The above is the motivation for developing HealOps.

# Deploying/Installing HealOps

1 When deploying HealOps to a node you will need to deploy:

    * The specific HealOps package for the IT Service/Entity you want to monitor and heal.
    * The HealOps module itself.

## Fixing failed states based on HealOps triggered alarms

    * Why not use the *.Tests.ps1 files, that "X" IT service/Entity is tested via, when you have had to manually remediate a failed IT service/Entity? You guessed it! That question was rhetorical. Of course you should. E.g.
        * These files are the files that will trigger the alarm again if you didn't fix the failed IT service/Entity properly.
        * They can assist you when troubleshooting.
            By:
            * Showing you what is wrong.
            * By running them recursively after having fixed "SOMETHING" to see if that made "X" work.

# Monitoring HealOps.

- Alerting if/when reporting fails.

The function Submit-EntityStateReport is used to report to a time-shift series database. If this fails, data in the TDB is not visualized via the monitoring system. So make sure to enable alerting in the monitoring system in the case of data gaps.

    - In Grafana this can be done under the "Alert" tab settings on a "Panel". Look for "If no data or all values are null" <-- set this to "Alerting". And configure notifications for the panel in order to alert someone in case of a panel alert.

I considered having the function itself alert, via e-mail, Slack or the like, however, as it is already built into Grafana and similar systems, I came to the conclusion that the need isn't there. Resulting in simpler code.

# Repairing a failed IT system or component state.

Repairing works when:

    * There is one test in each *.Tests.ps1 file.
    * Each *.Tests.ps1 file have a matching *.Repairs.ps1 file. E.g.
        * File "F" > iisLogs.Tests.ps1 have a corresponding >
        * File "F" > iisLogs.Repairs.ps1.
    * These two files needs to be adjacent to each-other.

Rules of thumb and design of the *.Repairs.ps1 file

    * The return should always be [Boolean] $true or $false

### The *.Repairs.ps1 file

1 Is functionless.

2 However, it can still have parameters.

    - E.g. of a *.Repairs.ps1 functionless parameter filled file.
    `
        # Define parameters
        [CmdletBinding()]
        [OutputType([Boolean])]
        param(
            [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Data from the result of testing the state of an IT Service/Entity.")]
            [ValidateNotNullOrEmpty()]
            $TestData
        )

        #############
        # Execution #
        #############
        CODE_TO_REMEDATE_FAILED_IT_SERVICE_/_ENTITY
    `

### The *.Stats.PS1 file

1. Is used for gathering stats on an component of an IT system.
2. The stats file will __NOT__ be invoked by Pester.

### The *.Tests.PS1 file

1 An global variable named ' passedTestResult ' has to be used for cases of state okay. This global variable is used to report to the backend the okay state of "X" IT Service/Entity

        - It has to fulfill:

            * Name > passedTestResult
            * Be global

        - E.g. (from inside *.Tests.ps1 Describe block)
        `
        It "return.http.200" {
            # Assert
            $global:passedTestResult = $requestResult.StatusCode
            $requestResult.StatusCode | Should Be 200;
        }
        `
    1a. If this variable has not been set it will be set to the numeric value -1. To indicate this and to distinguish between the two global variables passedTestResult and failedTestResult (read about that one below).

2 An global variable named ' failedTestResult ' has to be used for cases of state failed. This global variable is used to report to the backend the failed state of "X" IT Service/Entity

        - It has to fulfill:

            * Name > failedTestResult
            * Be global

        - E.g. (from inside *.Tests.ps1 Describe block)
        `
        It "return.http.200" {
            # Assert
            $global:failedTestResult = $requestResult.StatusCode
            $requestResult.StatusCode | Should Be 200;
        }
        `
    2a. If this variable has not been set it will be set to the numeric value -2. To indicate this and to distinguish between the two global variables passedTestResult and failedTestResult.

## Reporting

### Alerting On-call personnel based on reports to backend report system

    * Rule of thumb > HealOps sends data the external SaaS on-call system used. It is on that system that you configure rules for "X" IT service/Entity in regards to notify or not notify the on-call personnel. All HealOps should determine is the state of "X" IT service/Entity and if it is found to be in a failed state > try to remediate the state back to an okay state > if that fails > send a payload to the SaaS on-call management system where rules of "engagement" is defined.

### Metrics

Report data is based on metrics. Where metrics is in the form e.g. ' systemName.SystemComponent.SystemSubComponent '.

#### Metric values

    * OpenTSDB:
        * Only accepts numerical values for the metric value.

#### Naming scheme

The std. is:

    * Needed values:
        * Name of the IT Service/Entity.
        * Component/part of the IT service/Entity that was tested.
        * Tags >

    * Optional is the SystemSubComponent part of metric name.

    __e.g. >__ `town1.octopusdeploy.tentacle.`

    * The above name description is to be used when defining the "Describe" keyword value in the Pester *.Tests.ps1 file. As this is where the metric name will be derived from when reporting on a metric to the backend system.

#### On state test success

    * A global variable should be used to report the value to be used for the metric value. This global variable will be read by HealOps when reporting.
    This value needs to be a numerical type.
    * This global variable should be defined for each 'It' block in a Pester *.Tests.ps1 file.
    * The name of the global variable can only be == 'passedTestResult' (without the quotes)

#### On state test failed

    * A global variable should be used to report the value you want to report in case of a failed state. This global variable will be read by HealOps when reporting.
    This value needs to be a numerical type.
    * This global variable should be defined for each 'It' block in a Pester *.Tests.ps1 file.
    * The name of the global variable can only be == 'failedTestResult' (without the quotes)

#### Documentation on specific software.

__OpenTSDB__
    Is a time-shift series database system.

* Chunking needs to be enabled in the OpenTSDB config file. I.e.:
`
# Enable chunking
tsd.http.request.enable_chunked = true
tsd.http.request.max_chunk = 4096
`
* The conf file is could be located at e.g.
    * /opt/opentsdb/opentsdb-"version"/src/opentsdb.conf
* For the chunking config change to be picked you need to:
    * Add --config= e.g.:
    `
    /opt/opentsdb/opentsdb-${TSDB_VERSION}/build/tsdb tsd --config=/opt/opentsdb/opentsdb-${TSDB_VERSION}/src/opentsdb.conf --port=4242 --staticroot=/opt/opentsdb/opentsdb-${TSDB_VERSION}/build/staticroot --cachedir=/tmp --auto-metric
    `

## Required modules and dependencies

    - Required PowerShell modules
        * PowerShellGet
            - Minimum viable version: v1.5.0.0. If not errors like $psgettemp variable missing will pop-up.

## Security

- Find a way to scan HealOpsPackages for potential security issues. There is a high trust on these.

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

## Tasks

    * Windows Scheduled Tasks.
        * The type of task created is specifically a PowerShell job. Therefore the location, in "Scheduled Tasks" of the job will be > \Scheduled Tasks Root\Microsoft\Windows\PowerShell\ScheduledJobs
        * The job definition will be stored in the context of the user with which you created the job, even though the job is being executed as another user.
            >> e.g. $jobDef = [Microsoft.PowerShell.ScheduledJob.ScheduledJobDefinition]::LoadFromStore('TestingHealOps', 'C:\Users\%username%\AppData\Local\Microsoft\Windows\PowerShell\ScheduledJobs'); $jobDef.Run()"
        * Logs and results will be under >
    * Linux/MacOS cron job.
        *

## Terminology

    * HealOpsPackage > A unit of execution in relative to the testing and repairing of "X" IT Service/Entity.

## Testing

    *
    * E.g. of a *.Tests.ps1 file.
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

            $failedTestResult = $requestResult.StatusCode

            # FIGURE OUT THE CAUSE AND THROW HTTP STATUS NUM.
            throw 401
        }

        It "return.http.200" {
            # Assert
            $global:passedTestResult = $requestResult.StatusCode
            $requestResult.StatusCode | Should Be 200;
        }
    }
    `

## The self-update feature

    ''Update interval''
    - The property checkForUpdatesInterval_Hours is used to provide a interval value in hours representing the self-update frequency.
    ''UpdateMode''
    - This property controls what the self-update feature will update. There are three options:
        > All = Everything will be updated. HealOps itself, its required modules and the HealOps packages on the system.
        > HealOpsPackages = Only HealOps packages will be updated.
        > HealOps = Only HealOps itself and its required modules will be updated.
    - It is controlled by setting it to one of the above three values in the HealOpsConfig json file or when installing HealOps with the Install-HealOps deploy script.

    ''On HealOps packages''
    - These cannot AS IN CAN NOT! have required modules that are other HealOps packages. As of 180115.