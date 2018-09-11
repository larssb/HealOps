# Troubleshooting Package Management

## PowerShell package management cmdlet errors

__The Register-PSRepository cmdlet__

_Error:_
> `PackageManagement\Register-PackageSource : SourceLocation 'https://URI/nuget/HealOps' and ScriptSourceLocation 'https://URI/nuget/HealOps' should not be same for URI based repositories.`

_Fix:_
Ensure that the source locations are unique. By e.g. adding a trailing slash (/) onto one of them. It is a rather obscure error. I haven't digged into why it happens and I can't see why it is an issue.