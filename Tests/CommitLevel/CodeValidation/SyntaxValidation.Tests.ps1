Describe "PowerShell code is syntax valid: $ModuleName" {
    $functions = Get-ChildItem -Path Function: | Where-Object { $_.Source -eq $Settings.PesterSettingsModuleName }

    foreach ($function in $functions) {
        Context "$function - Syntax" {
            It "Should contain valid PowerShell code" {
                $AST = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content function:$function), [ref]$null, [ref]$null)
                $Errors = $null
                [System.Management.Automation.PSParser]::Tokenize($AST, [ref]$Errors) | Out-Null
                $Errors.Count | Should Be 0
            }
        }
    }
}