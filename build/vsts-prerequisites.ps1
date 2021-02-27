. "$PSScriptRoot\vsts-helpers.ps1"

# Install the required modules for testing.
Write-Header -Message "Installing Pester" -Colour Cyan
# Last Pester version 4 before version 5, which is not backwards-compatible.
Install-Module "Pester" -RequiredVersion "4.10.1" -Force -SkipPublisherCheck -Verbose
Import-Module "Pester" -Force -PassThru -Verbose

Write-Header -Message "Installing PSScriptAnalyzer" -Colour Cyan
Install-Module "PSScriptAnalyzer" -Force -SkipPublisherCheck -Verbose
Import-Module "PSScriptAnalyzer" -Force -PassThru -Verbose
