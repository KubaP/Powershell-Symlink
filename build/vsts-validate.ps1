. "$PSScriptRoot\vsts-helpers.ps1"

# Ensure that only the correct version (4.10.1) of Pester is loaded.
if (($null -ne (Get-Module -Name "Pester")) -and (Get-Module -Name "Pester").Version -ne [System.Version]::new(4,10,1))
{
	Remove-Module -Name "Pester" -Force -ErrorAction Stop
}
try
{
	Import-Module -Name "Pester" -RequiredVersion "4.10.1" -Force -ErrorAction Stop
}
catch
{
	Write-Header -Message "Could not load 'Pester' v4.10.1" -Colour Red
}

# Run internal pester tests.
& "$PSScriptRoot\..\Symlink\tests\pester.ps1"
