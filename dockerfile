FROM mcr.microsoft.com/powershell:6.1.0-ubuntu-18.04
LABEL author="https://github.com/larssb"

# Change the default shell to PowerShell
SHELL [ "pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';" ]

# Install modules required for building HealOps. Uses force to avoid "the untrusted prompt to stop us"
RUN Install-Module -Name Pester -Force; Install-Module -Name InvokeBuild -Force

# Set the intended command to use.
CMD [ "pwsh", "-Help" ]