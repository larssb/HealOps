# Tests
Describe "Functions are properly written." {
    $functions = Get-ChildItem -Path Function: | Where-Object { $_.Source -eq $Settings.PesterSettingsModuleName }

    foreach ($function in $functions) {
        Context "$function - Help" {
            <#
                - Collect function data to test on Retrieve the Help of the function
            #>
            $Help = Get-Help -Name $function -Full

            # Parse the function using AST
            $ast = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content function:$Function), [ref]$null, [ref]$null)

            <#
                - Test the function
            #>
            It "'DESCRIPTION' is not empty." {
                $Help.Description | Should not BeNullOrEmpty
            }

            It "'INPUTS' is not empty." {
                $Help.inputTypes | Should not BeNullOrEmpty
            }

            It "'OUTPUTS' is not empty." {
                $Help.returnValues | Should not BeNullOrEmpty
            }

            # Get the parameters declared in the Comment Based Help
            $RiskMitigationParameters = 'Whatif', 'Confirm'
            $HelpParameters = $Help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters

            # Get the parameters declared in the AST PARAM() Block
            $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath

            It "Parameters - Compare Count. Help vs. function AST." {
                $HelpParameters.name.count -eq $ASTParameters.count | Should Be $true
            }

            if (-not [String]::IsNullOrEmpty($ASTParameters)) {
                $HelpParameters | ForEach-Object {
                    It "Parameter $($_.Name) - Should be described in the help section."{
                        $_.description | Should not BeNullOrEmpty
                    }
                }
            }
        }
    }
}