# Define the folders to look through
$functionFolders = @('Deployment','Private','Public')

# Define vars
$moduleName = $($Settings.moduleName)
$moduleRoot = $($Settings.moduleRoot)
Describe "PowerShell code is syntax valid: $moduleName" {
    ForEach ($folder in $functionFolders) {
        $folderPath = Join-Path -Path $moduleRoot -ChildPath $folder
        $files = Get-ChildItem $folderPath -Include *.ps1, *.psm1, *.psd1 -Recurse

        if ($null -ne $files) {
            # TestCases are splatted to the script so we need hashtables
            $testCase = $files | Foreach-Object {@{file = $_}}
            It "<file> should be valid powershell" -TestCases $testCase {
                param($file)

                $file.fullname | Should Exist

                $contents = Get-Content -Path $file.fullname -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
                $errors.Count | Should Be 0
            }
        }
    }
}