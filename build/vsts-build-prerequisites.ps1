# Install the required powershell get module. This needs to be done sperately since after installation of the
# module, a new session must be created (the one which actually performs the build process).
#
# Version 2.2.2 is specifically installed as at the time of writing (2019/12/01),
# newer versions didn't actually publish the module to the psgallery website. This may be fixed now.
. "$PSScriptRoot\vsts-helpers.ps1"

Write-Header -Message "Installing PowershellGet v2.2.2" -Colour Cyan
Install-Module "PowershellGet" -SkipPublisherCheck -Force -RequiredVersion "2.2.2" -Verbose
