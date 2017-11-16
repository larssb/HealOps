<#
.DESCRIPTION
    This is a script function that will install HealOps on "X" system.

    It will:
        - Write the HealOps config json file which HealOps uses as its configuration storage.
        - Configure a HealOps task that will invoke the HealOps package/packages to test, heal and report on "X" system.
        - Install HealOps and its required modules and components.
.INPUTS
    <none>
.OUTPUTS
    Outputs to the terminal/host as it goes.
.NOTES
    If not interval is defined for the checkForUpdatesInterval_InDays parameter Install-HealOps will default to 7 a day interval.
.EXAMPLE
    "PATH_TO_THIS_FILE"/Instal-HealOps.ps1 -reportingBackend $reportingBackend -TaskName "MyHealOpsTask" -TaskRepetitionInterval 3 -
    Explanation of what the example does
.PARAMETER reportingBackend
    Used to specify the software used as the reporting backend. For storing test result metrics.
.PARAMETER checkForUpdates
    Whether to enable the check for updates feature or not.
.PARAMETER checkForUpdatesInterval_InDays
    The interval in days between checking for updates
.PARAMETER checkForUpdates_Repository
    The name of the repository on the Package Management system
.PARAMETER checkForUpdates_URI
    The URI of the repository on the Package Management system
.PARAMETER TaskName
    The name of the task.
.PARAMETER TaskRepetitionInterval
    The interval, in minutes, between repeating the task.
.PARAMETER InvokeHealOpsFile
    Specify the path to the file that is used to execute the HealOps package and its code. This file will then be called by the platforms job engine as scheduled.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Void])]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Used to specify the software used as the reporting backend. For storing test result metrics.")]
        [ValidateNotNullOrEmpty()]
        [String]$reportingBackend,
        [Parameter(Mandatory=$false, ParameterSetName="Default", HelpMessage="Whether to enable the check for updates feature or not.")]
        [Switch]$checkForUpdates,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The name of the task.")]
        [ValidateNotNullOrEmpty()]
        [String]$TaskName,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The interval, in minutes, between repeating the task.")]
        [ValidateNotNullOrEmpty()]
        [Int]$TaskRepetitionInterval,
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="Specify the path to the file that is used to execute the HealOps package and its code.
        This file will then be called by the platforms job engine as scheduled.")]
        [ValidateNotNullOrEmpty()]
        [String]$InvokeHealOpsFile
    )

    DynamicParam {
        if($checkForUpdates -eq $true) {
            # Check for updates functionality switch used. Set the needed parameters to configure the feature
            <#
                - checkForUpdatesInterval_InDays param.
            #>
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute
            $attributes.Mandatory = $false
            $attributes.HelpMessage = "The interval in days between checking for updates."
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $checkForUpdatesInterval_InDays_ParameterName = "checkForUpdatesInterval_InDays"
            [Type]$ParameterType = "Int"
            $checkForUpdatesInterval_InDays_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($checkForUpdatesInterval_InDays_ParameterName, $ParameterType, $AttributeCollection)
            if ($null -eq $checkForUpdatesInterval_InDays_Parameter.Value) {
                # No value was provided, fallback to once a week.
                $Parameter.Value = 7
            }

            <#
                - checkForUpdates_Repository param.
            #>
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute;
            $attributes.Mandatory = $true;
            $attributes.HelpMessage = "The name of the repository on the Package Management system.";
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute;

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute];
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $checkForUpdates_Repository_ParameterName = "checkForUpdates_Repository";
            [Type]$ParameterType = "String";
            $checkForUpdates_Repository_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($checkForUpdates_Repository_ParameterName, $ParameterType, $AttributeCollection);

            <#
                - checkForUpdates_URI param.
            #>
            # Configure parameter
            $attributes = new-object System.Management.Automation.ParameterAttribute;
            $attributes.Mandatory = $true;
            $attributes.HelpMessage = "The URI of the repository on the Package Management system.";
            $ValidateNotNullOrEmptyAttribute = New-Object Management.Automation.ValidateNotNullOrEmptyAttribute;

            # Define parameter collection
            $attributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute];
            $attributeCollection.Add($attributes)
            $attributeCollection.Add($ValidateNotNullOrEmptyAttribute)

            # Prepare to return & expose the parameter
            $checkForUpdates_URI_ParameterName = "checkForUpdates_URI";
            [Type]$ParameterType = "String";
            $checkForUpdates_URI_Parameter = New-Object Management.Automation.RuntimeDefinedParameter($checkForUpdates_URI_ParameterName, $ParameterType, $AttributeCollection);

            <#
                - Add all the check for updates feature parameters to a param dictionary object
            #>
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary;
            $paramDictionary.Add($checkForUpdatesInterval_InDays_ParameterName, $checkForUpdatesInterval_InDays_Parameter)
            $paramDictionary.Add($checkForUpdates_Repository_ParameterName, $checkForUpdates_Repository_Parameter)
            $paramDictionary.Add($checkForUpdates_URI_ParameterName, $checkForUpdates_URI_Parameter)

            return $paramDictionary;
        }
    }

    #############
    # Execution #
    #############
    Begin {
        <#
            - Sanity tests
        #>

    }
    Process {
        # Install HealOps and its required modules from the configured package management system


        <#
            - Specify and transform data for the HealOps config json file.
        #>
        $HealOpsConfig = @{}
        $HealOpsConfig.checkForUpdatesNext = "" # Real value provided here when HealOps is running and have done its first update cycle pass.

        # Finalize the object

        # Convert to JSON

        # Write the HealOps config json file
            ## Figure out the location of the PowerShell modules path.
        #Set-Content -Path

    }
    End {}