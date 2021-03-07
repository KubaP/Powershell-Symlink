. "$PSScriptRoot\vsts-helpers.ps1"

# Install the required modules for testing.
Write-Header -Message "Installing Pester" -Colour Cyan
# Last Pester version 4 before version 5, which is not fully backwards-compatible.
# The current "general" test scripts require v4 to run correctly.
Install-Module -Name "Pester" -RequiredVersion "4.10.1" -Force -SkipPublisherCheck -Verbose
Import-Module -Name "Pester" -RequiredVersion "4.10.1" -Force -PassThru -Verbose

Write-Header -Message "Installing PSScriptAnalyzer" -Colour Cyan
Install-Module -Name "PSScriptAnalyzer" -Force -SkipPublisherCheck -Verbose
Import-Module -Name "PSScriptAnalyzer" -Force -PassThru -Verbose
