$Params = @{
   ModuleName = 'SitecoreDSCResource'
   Name = 'SitecoreDSCResource'
   Property = @{'dsSitecoreInstance'='localhost'; Ensure = 'Answering'}
   Verbose = $true
}

$TestResult = Invoke-DscResource @Params -Method Test
If (-not $testResult.InDesiredState) {
   Invoke-DscResource -Method Set @Params
}