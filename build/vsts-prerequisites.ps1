. "$PSScriptRoot\vsts-helpers.ps1"

# Install the required modules for testing.
WriteHeader -Message "Installing Pester" -Colour Cyan
Install-Module "Pester" -RequiredVersion "4.10.1" -Force -SkipPublisherCheck -Verbose
Import-Module "Pester" -Force -PassThru -Verbose

WriteHeader -Message "Installing PSScriptAnalyzer" -Colour Cyan
Install-Module "PSScriptAnalyzer" -Force -SkipPublisherCheck -Verbose
Import-Module "PSScriptAnalyzer" -Force -PassThru -Verbose
