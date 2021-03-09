. "$PSScriptRoot\vsts-helpers.ps1"

# Install the required modules for testing.
Write-Header -Message "Installing Pester" -Colour Cyan
try
{
	# Last Pester version 4 before version 5, which is not fully backwards-compatible.
	# The current "general" test scripts require v4 to run correctly.
	Install-Module -Name "Pester" -RequiredVersion "4.10.1" -Force -SkipPublisherCheck -Verbose -ErrorAction Stop
	Import-Module -Name "Pester" -RequiredVersion "4.10.1" -Force -PassThru -Verbose -ErrorAction Stop
}
catch
{
	Write-Header "Could not install 'Pester' v4.10.1" -Colour Red
}

Write-Header -Message "Installing PSScriptAnalyzer" -Colour Cyan
try
{
	Install-Module -Name "PSScriptAnalyzer" -Force -SkipPublisherCheck -Verbose -ErrorAction Stop
	Import-Module -Name "PSScriptAnalyzer" -Force -PassThru -Verbose -ErrorAction Stop
}
catch
{
	Write-Header "Could not install 'PSScriptAnalyzer'" -Colour Red
}
