$path = "C:\file.txt"
$mode = "Open"
$access = "Read"
$share = "None"

$file = [System.IO.File]::Open($path, $mode, $access, $share)
#$file.close()

# READ-WRITE
$path = "C:\Program Files\WindowsPowerShell\Modules\HealOps\0.0.0.47\Artefacts\HealOpsConfig.json"
$mode = "Open"
$access = "ReadWrite"
$share = "Read"
$file = [System.IO.File]::Open($path, $mode, $access, $share)

# READ-THE-FILE
$reader = New-Object System.IO.StreamReader($file)
$text = $reader.ReadToEnd()
[PSCustomObject]$HealOpsConfig = $text | ConvertFrom-Json # !!! Remember PS v5- (out-string before convertfrom-json)

$reader.close()
$file.close()

# READ-ONLY
$pathAgain = "C:\Program Files\WindowsPowerShell\Modules\HealOps\0.0.0.47\Artefacts\HealOpsConfig.json"
$modeAgain = "Open"
$accessAgain = "Read"
$shareAgain = "ReadWrite"
$fileAgain = [System.IO.File]::Open($pathAgain, $modeAgain, $accessAgain, $shareAgain)




$path = "C:\Program Files\WindowsPowerShell\Modules\HealOps\Artefacts\HealOpsConfig.json"
$mode = "Open"
$access = "ReadWrite"
$share = "Read"

$file = [System.IO.File]::Open($path, $mode, $access, $share)

<#
    - Getting it to work

        1: Use # READ-WRITE section code
        2: try/catch around this. So when Invoke-HealOps session 'A' runs it gets a lock and session 'B' tries but IOException is thrown.
            2a: session 'A' reads the Healops config file with the reader as in the above
        3: In the catch block we do > $UpdateOnGoing = $true (have semaphore $UpdateOnGoing = $false in the Begin {} block of invoke-healops.)
        4: Still read the HealOps config file. Maybe it is best to do that in the finally {} block. Read it with Get-content as we already do in other places
        of healops or with a System.IO.File with a .share(ReadWrite) <-- doesn't really matter much.
#>
