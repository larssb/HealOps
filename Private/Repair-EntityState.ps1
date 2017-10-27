function Repair-EntityState() {
<#
.DESCRIPTION
    Wrapper function used to invoke a specific *.Repairs.ps1 file for a failed test.
.INPUTS
    <none>
.OUTPUTS
    [Boolean] on the status of the remediation.
.NOTES
    General notes
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
#.#PARAMETER Repair
    The ID of the repair to run on an IT Service/Entity that is in a faild state.
.PARAMETER TestFilePath
    A file containig the Pester tests to run. This should be a full-path to a file. From this file the Repairs file will be found.
#>

    # Define parameters
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        <#[Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="The ID of the repair to run on an IT Service/Entity that is in a faild state.")]
        [ValidateNotNullOrEmpty()]
        [int]$Repair,#>
        [Parameter(Mandatory=$true, ParameterSetName="Default", HelpMessage="A file containig the Pester tests to run. This should be a full-path to a file.
        From this file the Repairs file will be found.")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TestFilePath
    )

    #############
    # Execution #
    #############

    # Define the filename of the Repairs file.
    # TODO: If JSON do the necessary
    $repairsFile = $TestFilePath -replace "Tests","Repairs"
    Write-Verbose -Message "The repairs file was resolved to: $repairsFile"

    if (Test-Path -Path $repairsFile) {
        # Get contents of the repair file
        #$ast = [System.Management.Automation.PSParser]::Tokenize( (Get-Content -Path $repairsFile), [ref]$null)

        # Parse the AST to find the function name
        #$function = $ast.where({$_.content -eq "function" -and $_.Type -eq "Keyword"})

        <#
            - If the function keyword is on the first line and we used [-1] to get line of text we want
            the output would be a System.Char instead of System.String and then calling .Substring() would fail. As no such method is on
            a System.Char object.
        #>
        <#if ($function.Startline -eq 1) {
            $functionLine = (Get-Content -Path $repairsFile -TotalCount $function.StartLine)
        } else {
            $functionLine = (Get-Content -Path $repairsFile -TotalCount $function.StartLine)[-1]
        }
        $functionName = $functionLine.Substring($function.EndColumn) -replace "\(.+",""
        Write-Verbose -Message "The derived function name is $functionName"
#>
        # Dot-source the *.Repairs.ps1 file in order to load it into the current scope
        $repairResult = . $repairsFile

        # Run the repair
        #Invoke-Command -ScriptBlock { $functionName } -ArgumentList Repair $Repair
        #[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingInvokeExpression', '')]
        #$repairResult = Invoke-Expression "$functionName -Repair $repair"
        #$repairResult = Invoke-Expression "$functionName"
        Write-Verbose -Message "- The result of the repair is: $repairResult"

        # Report on the success of repairing the IT Service/Entity
        if($repairResult -eq $true) {
            # Report that it was repaired
            #Submit-ServiceStateReport -Status -Service

            # Return
            $true
        } else {
            # Alarm on-call personnel
            #Ping-Personnel -entityName $

            # Return
            $false
        }
    } else {
        throw "The repairs file $repairsFile could not be found.";
    }
}